---
# type: docs 
title: Neovim + ddu.vim で自動的にフィルタを開く方法
date: 2024-11-24T22:02:51+09:00
featured: false
draft: false
comment: true
toc: false
tags: [vim,neovim]
archives: 2024/11
---

## 前置き

ddu.vim をファイラーやバッファの切り替えやヘルプの検索などに活用していますが、日々使っているとちょっとした不満も出てきます。

どういう不満かと言いますと、`ddu#start()` で表示したリストを絞り込むには、リスト表示後に `<Cmd>call ddu#ui#do_action("openFilterWindow")<CR>` を実行してコマンドラインに移動する必要があるという点です。このコマンドを割り当てた `i` をタイプすれば絞り込みを始められますが、ヘルプ検索のように絞り込み必須の場合、毎回毎回 `i` をタイプするのが面倒だと感じていました。

そこで、特定のリストを表示した時だけ自動的に絞り込みが始まるという設定を行いましたので、その内容を備忘録として残します。

## 環境

```bash
$ nvim --version
NVIM v0.10.1
Build type: Release
LuaJIT 2.1.1713773202
```

```
ddu.vim: commit f6480d2
ddu-ui-ff: commit c1a8644
```

## 設定方法

私と同じことを考える人が他にもいるようで、ddu-ui-ff の [FAQ-25](https://github.com/Shougo/ddu-ui-ff/blob/8dc80e22d2e79f07b8458d351c4c33144be1c66c/doc/ddu-ui-ff.txt#L1151-L1161) にそのための設定が掲載されています。。

> Q: I want to start filter window when UI is initialized.
> 
> A: It is not supported. Because it has too many problems. But you can use the function.
> ```vim
> call ddu#start()
> autocmd User Ddu:uiDone ++nested
>       \ call ddu#ui#async_action('openFilterWindow')
> ```

問題が多いからその機能はサポートしないと回答されていますが、試してみてダメなら止めれば良いだけだと考えて、一度試してみることにしました

この機能の実装ですが、単純に考えれば FAQ で示されている設定を追加するだけでよさそうです。しかし、この設定を追加するだけでは別の問題が発生します。なぜなら、この設定は「ddu.vim の UI に全てのアイテムが表示された時（`Ddu:uiDone`）に `call ddu#ui#async_action('openFilterWindow')` を実行して絞り込みを開始する」というものなので、どのリストを表示しても自動的に絞り込みが始まってしまい、今度は絞り込み不要のリストを開いたときに `esc` をタイプして絞り込みを中止する必要が生じてしまいます。

よって、「特定のソースを開く場合のみ上記の設定を実行し、そのソースのリストを閉じたら `autocmd User Ddu:uiDone` で設定したオートコマンドを削除する」という処理を実装する必要があります。

結論から言いますと、以下の設定で上記の処理を実現できます。なお、私は Lua で設定していますので、Lua のコードを示します。

```lua
-- バグがあったため修正（2024/11/26）

-- オートコマンドを削除する時の目印となるグループを設定
-- グループ名は任意の値に設定できる
local ddu_vim_autocmd_group = vim.api.nvim_create_augroup('ddu_vim', {})

-- 自動的に絞り込みを開始するソースは、ヘルプとファイルとする。
vim.keymap.set('n', ';h', function() Ddu_start_with_filter_window('help') end)
vim.keymap.set('n', ';f', function() Ddu_start_with_filter_window('file_recursive') end)

-- リスト表示とリストにアイテムが表示されたら絞り込みを開始する設定を行う関数
function Ddu_start_with_filter_window(source_name)
  -- 引数で指示されたソースのアイテムリストを表示
  vim.fn['ddu#start']({name = source_name})
  -- リストにアイテムが表示されたら絞り込みを開始するというオートコマンドを設定
  return vim.api.nvim_create_autocmd("User",
    {
      -- リストにアイテムが表示された時点をオートコマンドのタイミングに設定
      pattern = 'Ddu:uiDone',
      -- 後でオートコマンドを削除するための目印としてグループを設定
      group = ddu_vim_autocmd_group,
      nested = true,
      callback = function()
        -- 絞り込みを開始する
        vim.fn['ddu#ui#async_action']('openFilterWindow')
      end,
    }
  )
end

-- 絞り込み終了時点で `Ddu_start_with_filter_window()` 関数で設定したオートコマンドを
-- 削除するというオートコマンドを設定する
vim.api.nvim_create_autocmd({'User'},
  {
    -- 絞り込みウィンドウを抜けた時点を自動コマンド実行のタイミングに設定
    pattern = 'Ddu:ui:ff:closeFilterWindow',
    callback = function()
      -- `Ddu_start_with_filter_window()` 関数で設定したオートコマンドの ID を取得
      -- 引数を Table で渡すと名前付き引数のように扱える
      local autocmd_id = Get_autocmd_id({group = ddu_vim_autocmd_group, pattern = 'Ddu:uiDone'})
      
      if autocmd_id ~= 0 then
        -- `Ddu_start_with_filter_window()` 関数で設定したオートコマンドを削除
        -- これを忘れるとリストを表示するたびに絞り込みが始まってしまう
        vim.api.nvim_del_autocmd(autocmd_id)
      end
    end
  }
)

-- 引数に対応するオートコマンドの ID を返す関数
-- 引数は Table で渡されているので `args.xx` の形で取り出す
function Get_autocmd_id(args)
  local pcall_result, function_return = pcall(
    vim.api.nvim_get_autocmds, { group = args.group, pattern = { args.pattern } }
  )
  if pcall_result then
    return function_return[1].id -- lua の配列の添字は 1 から始まる
  else
    return 0
  end
end
```

コメントに各コードの意味を記載していますが、`Ddu_start_with_filter_window()` で設定したオートコマンドを絞り込み終了時点で削除しなかった場合、それ以降はリストを表示すると自動的に絞り込み処理が始まります。そのため `vim.api.nvim_del_autocmd(autocmd_id_openfilterwindow)` でオートコマンドを削除しています。この設定で少々つまずきました。

なお、このオートコマンドの削除は `nvim_get_autocmds()` の検索結果が1つだけということを前提にしていますので、`group` と `pattern` で検索してヒットするオートコマンドが2つ以上あると処理が破綻します。そのため、`ddu_vim_autocmd_group = vim.api.nvim_create_augroup('ddu_vim', {})` で用意した目印をオートコマンド作成時の `group` に設定しています。

この設定により、ヘルプやファイルのリストを表示したら自動的に絞り込みを始められる一方、それ以外のリストを表示した時は必要な時だけ絞り込みを行うという動作を実現できるようになりました。

## 補足

リストを表示したら自動的に絞り込みを開始するという設定は、以前は `startFilter = true` という設定を追加するだけで可能だったようです。しかし、この設定は、問題が多すぎるということで2024年3月11日に削除されています（該当の[コミット](https://github.com/Shougo/ddu-ui-ff/commit/1d0a13f80026e977175a9419aecb46b98fa57ca4)）。

