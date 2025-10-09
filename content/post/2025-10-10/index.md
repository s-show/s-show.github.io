---
title: コマンド履歴ウィンドウに曖昧検索機能を追加する方法 # Title of the blog post.
date: 2025-10-10T00:00:05+09:00 # Date of post creation.
featured: false
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: true
usePageBundles: false # Set to true to group assets like images in the same folder as this post.
featureImage: '' # Sets featured image on blog post.
featureImageAlt: '' # Alternative text for featured image.
figurePositionShow: true # Override global value for showing the figure label.
tags: [Neovim]
archives: 2025/10
comment: true # Disable comment if false.
---

この記事は [Vim 駅伝](https://vim-jp.org/ekiden/) の 2025/10/10 の記事です。
前回の記事は、私の [Quickfix を Fuzzy Finder やバッファ管理などの UI として使う方法 | 閑古鳥ブログ](https://kankodori-blog.com/post/2025-10-08/) でした。

## 前置き

コマンドラインウィンドウは Vim/Neovim の標準機能ですが、これまで全然使っていませんでした。というよりも、`:q` がタイプミスで `q:` となって意図せずにコマンドラインウィンドウが開くことがあり、イライラの原因になっていました。そのため、コマンドの再実行は [snacks.nvim](https://github.com/folke/snacks.nvim) で実行していました。

しかし、[前回の記事](https://kankodori-blog.com/post/2025-10-08/)の方法で snacks.nvim を使わずに曖昧検索などをサクサク実行できるようになりましたので、コマンドの再実行も snacks.nvim を使わずにサクサクできるようになりたいと思うようになりました。

そこで、コマンドラインウィンドウを活用する方法を模索していたところ、[vim-fuzzyhistory](https://github.com/kuuote/vim-fuzzyhistory) というプラグインを発見しました。このプラグインはコマンドラインウィンドウに曖昧検索を追加するもので、コマンドラインウィンドウでも絞り込み検索ができることを知りました。

ここまで来れば後は実装するだけであり、私の場合は絞り込み機能があれば用は足りそうなので、AI の力を借りて実装しました。

## 実際の動作

コマンドラインウィンドウを開いてから `/` をタイプするとコマンドラインに移動しますので、検索クエリを入力して絞り込みしていきます。絞り込み後に `<Esc>` をタイプすれば元に戻ります。

{{< video src="https://github.com/s-show/s-show.github.io/raw/refs/heads/main/content/post/2025-10-10/images/cmdwin.mp4" type="video/webm" preload="auto" >}}

## 実装

実装は以下のとおりです。

```lua
local fuzzy_rank = require('util.fuzzy_rank')

-- コマンドラインを使ってリアルタイムな曖昧検索
local function cmdline_fuzzy_search()
  local buf = vim.api.nvim_get_current_buf()
  local original_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- 検索前の履歴を一時退避
  vim.b.cmdwin_original_lines = original_lines

  -- 検索状態を保持するフラグ
  local search_active = true
  local group = vim.api.nvim_create_augroup('CmdwinFuzzySearch', { clear = true })

  -- 入力のためにコマンドラインに移動
  vim.api.nvim_feedkeys(':', 'n', false)

  -- CmdlineChangedイベントでリアルタイムフィルタリング
  vim.api.nvim_create_autocmd('CmdlineChanged', {
    group = group,
    callback = function()
      if not search_active then return end
      local query = vim.fn.getcmdline()
      -- 検索文字を全て削除した場合の処理
      if query == '' then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, original_lines)
      else
        local filtered = fuzzy_rank.rank(query, original_lines)
        if #filtered > 0 then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, filtered)
        else
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '-- No matches found --' })
        end
      end
      -- コマンドラインを再描画
      vim.cmd('redraw')
      vim.cmd('normal! gg')
    end
  })

  -- Enterキーで検索を確定するキーマッピングを追加
  vim.api.nvim_create_autocmd('CmdlineEnter', {
    group = group,
    once = true,
    callback = function()
      vim.keymap.set('c', '<CR>', function()
        search_active = false
        vim.api.nvim_clear_autocmds({ group = group })
        -- キーマッピングを削除
        pcall(vim.keymap.del, 'c', '<CR>')
        -- 空のコマンドを実行してコマンドラインを閉じる
        return '<C-u><Esc>'
      end, { expr = true })
    end
  })

  -- ESCキーでキャンセル
  vim.api.nvim_create_autocmd('CmdlineLeave', {
    group = group,
    once = true,
    callback = function()
      vim.schedule(function()
        if search_active then
          -- キャンセルされた場合は元に戻す
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, original_lines)
        end
        search_active = false
        vim.api.nvim_clear_autocmds({ group = group })
        -- キーマッピングを削除
        pcall(vim.keymap.del, 'c', '<CR>')
      end)
    end
  })
end

vim.api.nvim_create_autocmd(
  { 'CmdwinEnter' },
  {
    callback = function()
      vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = true })
      -- コマンドライン曖昧検索
      vim.keymap.set('n', '/', cmdline_fuzzy_search, {
        buffer = true,
        desc = 'Fuzzy search with command line'
      })

      -- このキーマップがあると `<Esc>` による復元処理がワンテンポ遅くなるので一時的に削除する
      pcall(vim.keymap.del, 'n', '<Esc><Esc>')
      -- <Esc> で検索結果を破棄してコマンド履歴を復元する
      vim.keymap.set('n', '<Esc>', function()
        local buf = vim.api.nvim_get_current_buf()
        local original = vim.b.cmdwin_original_lines
        if original then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)
          vim.b.cmdwin_original_lines = nil
          vim.cmd('normal! G')
        end
      end, { buffer = true, desc = 'restore command history.' })
      vim.fn["ddc#custom#patch_global"]({
        ui = 'none'
      })
    end
  }
)

vim.api.nvim_create_autocmd(
  { 'CmdwinLeave' },
  {
    callback = function()
      pcall(vim.keymap.del, 'n', 'q')
      pcall(vim.keymap.del, 'n', '/')
      pcall(vim.keymap.del, 'n', '<Esc>')
      vim.keymap.set('n', '<ESC><ESC>', '<Cmd>nohlsearch<CR>', { silent = true })
      vim.fn["ddc#custom#patch_global"]({
        ui = 'pum'
      })
    end
  }
)
```

大まかな処理の流れは次のとおりです。

まず、コマンドラインウィンドウに入った時点で、`CmdwinEnter` イベントを使って `/` に絞り込み処理を担当する `cmdline_fuzzy_search()` 関数を割り当てます。

`cmdline_fuzzy_search()` 関数では、`vim.api.nvim_feedkeys(':', 'n', false)` で `:` キーを送信してコマンドラインに移動し、検索クエリを入力できるようにします。

それから、`CmdlineChanged` イベントを使ってコマンドラインに入力された文字を `vim.fn.getcmdline()` を使ってリアルタイムに取得し、その文字列をクエリにして絞り込みしていきます。絞り込み処理は実際には曖昧検索という形で実行していますが、核となる検索機能と順位付けの処理は、[前回の記事](https://kankodori-blog.com/post/2025-10-08/)で登場したファイルの曖昧検索と同じ関数を使っています。

絞り込み処理が進んで目当てのコマンドが表示されたら、`Enter` キーを押して検索結果を確定します。このキーの割り当ては、`CmdlineEnter` イベントを使って実施しています。

また、間違って検索結果を確定したときに備えて、`CmdwinEnter` イベントでノーマルモードの `Escape` キーに履歴復元機能を割り当てています。そのために、`cmdline_fuzzy_search()` 関数ではオリジナルの履歴を退避してから検索を実施しています。なお、`CmdlineLeave` イベントは検索状態のクリーンアップと、キャンセル時の自動復元を担当しています。

## 実装した感想

これまで使いこなせていなかったコマンドラインウィンドウですが、絞り込み機能を付け足すことで便利に使えるようになり、コマンド再実行でも snacks.nvim を使うことが無くなりました。

今回のカスタマイズも[前回の記事](https://kankodori-blog.com/post/2025-10-08/)同様に Neovim のカスタマイズの奥深さが分かるもので、こういうカスタマイズができるのも Neovim を使うことの楽しさだと思います。

