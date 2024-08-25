---
# type: docs 
title: Lua で ddu.vim のカスタムアクションを実装する
date: 2024-08-25T16:18:23+09:00
featured: false
draft: false
comment: true
toc: false
tags: [vim,neovim]
---

## 前置き

Neovim のプラグインの [ddu.vim](https://github.com/Shougo/ddu.vim) を導入してバッファ切り替えやコマンド履歴からのコマンド実行やファイラーとして便利に使っているのですが、[ddu.vimのアクション周りを便利にしよう](https://zenn.dev/kamecha/articles/18d244603c85fd) という記事を見てカスタムアクションを導入したいと思いました。

ただ、上記の記事は Vimscript を使って設定していますが、私は Lua で設定していますので、導入では少々苦労しました。

ネットで調べても Lua でカスタムアクションを導入している記事は見当りませんでしたので、備忘録として注意点をメモします。


## 環境

### OS

```
エディション	Windows 11 Pro
バージョン	23H2
インストール日	2022/07/11
OS ビルド	22631.4108
エクスペリエンス	Windows Feature Experience Pack 1000.22700.1034.0
```

### Neovim

```powershell
❯ nvim --version
NVIM v0.10.1
Build type: Release
LuaJIT 2.1.1713484068
Run "nvim -V1 -v" for more info
```

また、Neovim には [ddu-source-action](https://github.com/Shougo/ddu-source-action) を追加しており、ddu.vim の UI で `a` を押せばi temAction として実行できるアクションをdduに表示して絞り込みができるようにしています。

```lua
-- 無関係の設定は省略しています
vim.api.nvim_create_autocmd("FileType", {
  pattern = "ddu-ff",
  callback = function()
    vim.keymap.set({ "n", "i" }, "a", [[<Cmd>call ddu#ui#do_action('chooseAction')<CR>]], { noremap = true, silent = true, buffer = true })
  end,
})
```


## 実装

私が導入したいカスタムアクションは、ファイラーとして使っているときに、選択したファイルの相対パスをカーソル位置に挿入するというものです。

そこで、まず前述の記事に「まず登録する関数の先頭で試しにechomsg a:args等を実行して、受け取る引数に何が入っているかを確かめてみると良い」とありましたので、関数と関数呼び出しを以下のとおり設定して受け取る引数の内容を確認しようとしました。

```lua
function InsertFilepath()
  vim.cmd('echomsg a:args')
  return 0
end
vim.fn['ddu#custom#action']('source', 'file_rec', 'insertPath', 'InsertFilepath')
```

これで `chooseAction` で呼び出したアクションの中に `insertPath` が登録されたのですが、アクションを実行しても「未知の関数です」というエラーになってしまいました。前述の記事と同様に VimScript で設定を書いて `vim.cmd()` で囲めばエラーにはならないのですが、設定は可能な限り Lua で書くようにしているので、他の方法も模索してみました。

で、結論を書きますと、関数を別途定義して呼び出すのではなく、即時関数にすればきちんとアクションを実行できました。それを踏まえて書いた設定は以下のとおりです。

```lua
vim.fn['ddu#custom#action']('source', 'file_rec', 'insertPath', function (args)
  local selectedFilePath = vim.fn.substitute("."..args["items"][1]["word"], "\\", "/", 'g')
  local beforeCursor = vim.fn.strcharpart(vim.fn.getline('.'), 0, vim.fn.getcharpos('.')[3])
  local afterCursor = vim.fn.strcharpart(vim.fn.getline('.'), vim.fn.getcharpos('.')[3], vim.fn.strchars(vim.fn.getline('.')))
  local newLine = beforeCursor..selectedFilePath..afterCursor
  vim.fn.setline('.', newLine)
  return 0
end)
```

実際の動作は次のとおりです。

{{< video src="./image/preview.mp4" type="video/mp4" preload="auto" >}}


## 補足

### `args` の内容

`chooseAction` からカスタムアクションを呼び出したときに渡される引数の `args` について、以下のコードで内容をレジスタに登録してから別のバッファに貼り付けて確認したところ、以下の内容となっていました。

```lua
vim.fn['ddu#custom#action']('source', 'file_rec', 'insertPath', function (args)
  local selectedFilePath = vim.fn.substitute("."..args["items"][1]["word"], "\\", "/", 'g')
  local beforeCursor = vim.fn.strcharpart(vim.fn.getline('.'), 0, vim.fn.getcharpos('.')[3])
  local afterCursor = vim.fn.strcharpart(vim.fn.getline('.'), vim.fn.getcharpos('.')[3], vim.fn.strchars(vim.fn.getline('.')))
  local newLine = beforeCursor..selectedFilePath..afterCursor
  vim.fn.setline('.', newLine)
  vim.fn.setreg('a', vim.inspect(args)) -- 確認のために追加したコード
  return 0
end)
```

```
{
  actionParams = vim.empty_dict(),
  context = {
    bufName = "C:\\Users\\username\\AppData\\Local\\nvim\\init.lua",
    bufNr = 3,
    cwd = "C:\\Users\\username\\AppData\\Local\\nvim",
    done = true,
    doneUi = true,
    input = "",
    maxItems = 111,
    mode = "n",
    path = "C:\\Users\\username\\AppData\\Local\\nvim",
    pathHistories = {},
    winId = 1000
  },
  items = { {
      __columnTexts = vim.empty_dict(),
      __expanded = false,
      __groupedPath = "",
      __level = 0,
      __sourceIndex = 0,
      __sourceName = { "file_rec" },
      action = {
        isDirectory = false,
        path = "C:\\Users\\username\\AppData\\Local\\nvim\\lua\\plugins\\cmp-path.lua"
      },
      display = " lua\\plugins\\cmp-path.lua",
      highlights = { {
          col = 1,
          hl_group = "DduDevIconLua",
          name = "ddu_devicon",
          width = 3
        } },
      kind = "file",
      matcherKey = "lua\\plugins\\cmp-path.lua",
      word = "lua\\plugins\\cmp-path.lua"
    } },
  options = {
    actionOptions = vim.empty_dict(),
    actionParams = vim.empty_dict(),
    actions = {},
    columnOptions = vim.empty_dict(),
    columnParams = vim.empty_dict(),
    expandInput = false,
    filterOptions = vim.empty_dict(),
    filterParams = vim.empty_dict(),
    input = "",
    kindOptions = {
      action = {
        defaultAction = "do"
      },
      file = {
        defaultAction = "open"
      }
    },
    kindParams = vim.empty_dict(),
    name = "file_recursive",
    postFilters = {},
    profile = false,
    push = false,
    refresh = false,
    resume = false,
    searchPath = "",
    sourceOptions = {
      _ = {
        ignoreCase = true,
        matchers = { "matcher_substring" }
      },
      file_rec = {
        actions = {
          insertPath = "e91b97c2196bc99e62c0f12111750920802d8bf4aea17d68a81a85fb5ffef268"
        }
      }
    },
    sourceParams = vim.empty_dict(),
    sources = { {
        name = { "file_rec" },
        options = {
          converters = { "converter_devicon" }
        },
        params = {
          ignoredDirectories = { "node_modules", ".git", "dist", ".vscode" }
        }
      } },
    sync = false,
    ui = "ff",
    uiOptions = vim.empty_dict(),
    uiParams = {
      ff = {
        floatingBorder = "rounded",
        previewFloating = true,
        previewFloatingBorder = "rounded",
        previewFloatingTitle = "Preview",
        previewSplit = "vertical",
        prompt = "> ",
        split = "floating"
      }
    },
    unique = false
  }
}
```


### カスタムアクションを追加したかった理由

[ddc.vim](https://github.com/Shougo/ddc.vim/) を導入して LSP やコマンドやファイルパスの補完を実現していますが、ファイルパスの補完だけちょっと動作にもたつきがあるのと、ディレクトリ構造を順番に入力するのがちょっと面倒だったためです。

それでも他に方法がなければ ddc.vim の補完を使うのですが、ddu.vim もファイルパスを使っている以上、カスタムアクションが導入できればファイルパスを一発で書けるのではないかと思い、カスタムアクションの導入に挑戦しました。

結果的に希望どおりの動作が実現できたので良かったです。
