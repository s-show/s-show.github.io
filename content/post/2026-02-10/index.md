---
title: "ddu.vim を再び活用するために実行したこと" # Title of the blog post.
date: 2026-02-05T22:15:38+09:00 # Date of post creation.
featured: false
draft: false
comment: true
toc: false
tags: [neovim]
archives: 2026/2
---

## 前置き

この記事はVim駅伝の2026-02-25の記事です。

前回の記事はmikoto2000さんの[Windows のターミナルで Vim の OSC52 プラグインのコピーのみを有効にする - mikoto2000 の日記](https://mikoto2000.blogspot.com/2026/02/windows-vim-osc52.html) でした。

Vim駅伝は常に参加者を募集しています。詳しくは[こちらのページ](https://vim-jp.org/ekiden/)をご覧ください。

---

[ddu.vim](https://github.com/Shougo/ddu.vim) は Vim/Neovim で使えるファジーファインダーで、私が Neovim を使い始めた頃にインストールして利用していたものの、その後、多機能で簡単に使える [snacks.nvim](https://github.com/folke/snacks.nvim) が登場すると使用頻度がかなり下がっていました。

しかし、Snacks.nvim は使わない機能も多く、また、設定を詰めていくことでエディタを自分に合わせていくことこそが Neovim を使う楽しみであることを踏まえて、ddu.vim をもう一度活用するべくソースを追加したりフィルターを自作したりしたので、その成果と設定中に気付いたことをまとめます。

なお、本記事では "sources" と "ソース" のように表記揺れのような表現が複数あるので、本記事での使い分けを以下のとおり定義します。

- sources: ddu.vim で開くアイテムを指定する設定項目
- ソース: ddu.vim で開くアイテムを取得するプラグインで、`sources` に指定するもの。
- matchers: ddu.vim が取得したアイテムのフィルタリングを指定する設定項目
- マッチャー: ddu.vim で開いたアイテムをフィルタリングするプラグインで、`matchers` に指定するもの。

## 環境

```bash
> nvim --version
NVIM v0.12.0-nightly+a5e5ec8
Build type: Release
LuaJIT 2.1.1741730670
Run "nvim -V1 -v" for more info
```

ddu.vim: commit 5b11c90


## 複数のソースのアイテムをまとめて表示

Snacks.nvim には 'picker' というファジーファインダーがあり、ファイルリストやカラースキーマやコマンド履歴まで様々なアイテムを曖昧検索できますが、その中に 'smart' というアイテムがあります。

これは、ファイルリスト・バッファリスト・履歴を良い感じにまとめて表示してくれるもので、便利でよく使っていることから、まずはこれを ddu.vim で再現することにしました。

### ソースの指定方法

ddu.vim のソースには[ファイルリスト](https://github.com/Shougo/ddu-source-file_rec)・[バッファリスト](https://github.com/shun/ddu-source-buffer)・[ファイル履歴](https://github.com/kuuote/ddu-source-mr)があるので、この3つのソースのアイテムをまとめて表示すれば Lazy.nvim の 'smart' に近い動作になります。

ddu.vim で複数のソースのアイテムをまとめて表示するには、以下のコードのように `sources` に複数のソースを指定すれば OK です。なお、`"smart"` の部分は任意の名称を指定できます。

```lua
vim.fn["ddu#custom#patch_local"]("smart", {
  sources = {
    {
      name = { "buffer" }
    },
    {
      name = { "mr" },
    },
    {
      name = { "file_rec" }
    }
  }
})
```

`matchers` で加工しない限り、アイテムの読み込み順は指定した順番になります（上記の例なら `buffer` -> `mr` -> `file_rec` となります）。

### オプションの指定方法

以下のとおり `sourceOptions` にソース毎のオプションを指定します。

```lua
vim.fn["ddu#custom#patch_local"]("smart", {
  sources = {
    {
      name = { "buffer" }
    },
    {
      name = { "mr" }
    },
    {
      name = { "file_rec" }
    },
  },
  sourceOptions = {
    buffer = {
      matchers = { 'matcher_relative' }
    },
    mr = {
      matchers = { 'matcher_relative' }
    }
  }
})
```

`'matcher_relative'` は「ファイルのパスがカレントディレクトリに合致するものだけ取り出す」マッチャーで、これを指定すると、カレントディレクトリ以外のファイルを開いているバッファと、カレントディレクトリ以外のファイル履歴は表示されなくなります。

### アイテムの取得元の表示

表示されたアイテムがどのソースで取得されたアイテムか確認したい場合、`displaySourceName` に `"long"` または `"short"` を設定します。ただし、この設定は UI に [Shougo/ddu-ui-ff: Fuzzy finder UI for ddu.vim](https://github.com/Shougo/ddu-ui-ff) を使っている場合の設定なので、他の UI を使っている場合はそちらの設定に合わせる必要があります。

```lua
vim.fn["ddu#custom#patch_local"]("smart", {
  uiParams = {
    ff = {
      displaySourceName = "long",
    }
  },
})
```

### 重複削除

ファイルリスト・バッファリスト・最近使ったファイルをまとめて表示すると、同じファイルが違うソースからのアイテムとして重複表示されることがあります。

Lazy.nvim では重複表示されないので同様にフィタリングしようとしたものの、まず、既存のマッチャーに重複したアイテムを削除するものはありませんでした。また、重複を取り除くには複数のソースのアイテムを合体してから処理する必要があるものの、`matchers` で指定したマッチャーはソース毎に適用されるので、別の方法を探すことにしました。

最初は「ファイルリスト・バッファリスト・最近使ったファイル」を重複を削除しつつまとめて取得できるソースを作りましたが、このソースを作ったことを Slack の vim-jp で報告したら、ddu.vim の作者の Shougo 氏から「`postFilters` を使えば複数のソースのアイテムを合体した後にマッチャーを適用できる」と教えてもらったので、作成したソースは早々にお蔵入りにした上で、重複するパスを除外するマッチャーを作成することにしました。

完成したマッチャーは [s-show/ddu-filter-deduplicate\_path](https://github.com/s-show/ddu-filter-deduplicate_path) で、これを `postFilters` に設定すれば、3つのソースから取得したフィルタリング済みアイテムに追加のフィルタリングをかけて重複を削除できます。

```lua
vim.fn["ddu#custom#patch_local"]("smart", {
  postFilters = {
    'deduplicate_path',
  }
})
```

なお、私はファイルリスト・バッファリスト・最近使ったファイルを編集日時の順番で並べたいので、[kuuote/ddu-filter-sorter\_mtime](https://github.com/kuuote/ddu-filter-sorter_mtime) を `postFilters` に追加しています。

`postFilters` に指定したマッチャーは順番に適用されるので、こう設定すれば、`sorter_mtime` の処理が行われたアイテムリストが `deduplicate_path` に渡されて処理されることとなります。

```lua
vim.fn["ddu#custom#patch_local"]("smart", {
  postFilters = {
    'sorter_mtime',
    'deduplicate_path',
  }
})
```

これでアイテムのリストを編集日時の順番で並べ替えてから重複を取り除く処理が可能になる。

### キーバインド

ここまで設定すると ddu.vim で Snacks.nvim の picker の smart に近い動作を実現できるので、任意のキーに `"smart"` で定義した設定で ddu.vim を開くキーバインドを割り当てます。ここでは `<leader> -> g -> s` の3ストロークキーに割り当てています。

```lua
vim.keymap.set('n', '<leader>gs', function()
  vim.fn['ddu#start']({ name = 'smart' })
end)
```

## インストール済みソースのリストからソースを選択する方法

Snacks.nvim でも ddu.vim でも、使用頻度が高いソースについてはキーバインドを設定してすぐに開けるようにしていますが、使用頻度が低いソースまでキーバインドを設定するのは面倒であり、また、使用頻度が低いからキーバインド自体を忘れてしまうという問題があります。

この問題に対し、Snacks.nvim は「どのソースを開くか」を選択する画面を用意して対応しており、これが非常に便利なので、同じ機能を ddu.vim にも導入することにしました。

幸い、[4513ECHO/ddu-source-source](https://github.com/4513ECHO/ddu-source-source) が同じ機能を提供してくれるソースなので早速導入したものの、一部のソースが表示されないという不具合に遭遇しました。

そこでこのソースのコードを確認したところ、このソースはソースプラグインのディレクトリ構造がパターン1であることを想定しており、パターン2のディレクトリ構造を想定していないことが判明しました。

```
パターン1
source_name/
└─denops/
  └─@ddu-sources/
    └─source_name.ts

パターン2
source_name/
└─denops/
  └─@ddu-sources/
    └─source_name/
      └─main.ts
```

これでは常用するには厳しいので、Fork して修正したものを[プルリク](https://github.com/4513ECHO/ddu-source-source/pull/3)して修正を依頼し、プルリクが承認されるまでは[Fork版](https://github.com/s-show/ddu-source-source/tree/main)を使ってこの動作を実現しています。

## 同じソースをパラメータを変えて呼び出す

### file_rec を異なるパラメータで呼び出す

[xwmx/nb:](https://github.com/xwmx/nb) を使ってメモを書いていますが、作業中に自分のメモを見たいときに `e ~/.nb/home/***.md` と入力するのは面倒だし、そもそも日付を元にしたファイル名だけではどのファイルを開くべきか判断ができないので、ddu.vim でメモのリストをプレビュー付きで表示できるようにしました。

メモは `.md` ファイルなので、カレントディレクトリのファイルリスト表示に使っている [ddu-source-file_rec](https://github.com/Shougo/ddu-source-file_rec) の `sourceOptions.file_rec.path`  パラメータを変えてメモのリストを表示することとしました。

そこで、ddu-source-file_rec の `ddu#custom#patch_local` の `name` をカレントディレクトリ用の名前とは違うものを設定し、それから `sourceOptions.file_rec.path` に nb のディレクトリのフルパスを指定して起動すれば、nb のメモリストが表示されます。

実際のコードは以下のとおりで、参考として、カレントディレクトリのファイルリストを開く設定も示します。同じソースを異なるパラメータで呼び出せることが実感できると思います。

```lua
-- nb のメモリストを表示する設定
vim.fn["ddu#custom#patch_local"]("nb_list", {
  sources = {
    {
      name = { "file_rec" },
      options = {
        converters = {
          "converter_devicon",
        },
      },
      params = {
        ignoredDirectories = {
          ".cache",
          ".git",
        },
      },
    },
  },
  sourceOptions = {
    file_rec = {
      path = { '/home/username/.nb' },
    }
  },
})

vim.keymap.set('n', '<leader>nl', function()
  vim.fn['ddu#start']({ name = 'nb_list' })
end)

-- カレントディレクトリのファイルリストを開く設定
vim.fn["ddu#custom#patch_local"]("file_rec", {
  sources = {
    {
      name = { "file_rec" },
      options = {
        converters = {
          "converter_devicon",
        },
      },
      params = {
        ignoredDirectories = {
          "node_modules",
          ".git",
          "dist",
          ".vscode",
        },
      },
    },
  },
  sourceOptions = {
    file_rec = {
      sorters = { 'sorter_alpha' },
    }
  },
})

vim.keymap.set('n', '<leader>gf', function()
  vim.fn['ddu#start']({ name = 'file_rec' })
end)
```


### rg を異なるパラメータで呼び出す

同じ要領で、ddu.vim と [BurntSushi/ripgrep:](https://github.com/BurntSushi/ripgrep) を繋ぐソースである [shun/ddu-source-rg](https://github.com/shun/ddu-source-rg) で nb のメモを検索するため、以下の設定を追加しています。先程と同様に、ddu-source-rg でカレントディレクトリを検索するための設定も併記します。

```lua
vim.fn["ddu#custom#patch_local"]("nb_rg", {
  sources = {
    {
      name = { "rg" },
      options = {
        matchers = {},
        volatile = true,
        path = GetNbDir() 
      },
    }
  },
  uiParams = {
    ff = {
      ignoreEmpty = false,
      autoResize = false,
    }
  }
})

vim.fn["ddu#custom#patch_local"]("rg", {
  sources = {
    {
      name = { "rg" },
      options = {
        matchers = {},
        volatile = true,
      },
    }
  },
  uiParams = {
    ff = {
      ignoreEmpty = false,
      autoResize = false,
    }
  }
})
```

なお、上記の設定にある `GetNbDir()` は、nb のカレントディレクトリを `nb env` の出力から取得する自作関数です。これにより、nb のカレントディレクトリをハードコーディングする必要がなくなります。

```lua
function GetNbDir()
  local handle = io.popen("nb env | grep NB_DIR=")
  if handle then
    local result = handle:read("*a")
    local success, err_msg, err_code = handle:close()
    if success and result ~= "" then
      local path = vim.fn.substitute(result, 'NB_DIR=', '', "g")
      path = vim.fn.substitute(path, '\n', '', "g")
      return path
    else
      return ""
    end
  else
    return ""
  end
end
```

## ソースに応じて UI のキーバインドを変更

特定のソースを開いたときだけ有効にしたいキーバインドがあり、具体的には、コマンド履歴のソースである [matsui54/ddu-source-command\_history](https://github.com/matsui54/ddu-source-command_history) を開いたときだけ `dd` に履歴の削除を割り当てて、かつ、`e` に履歴を編集して実行する機能を割り当てるというものです。

最初、この機能を実現するため、ddu.vim 本体や [Shougo/ddu-ui-ff](https://github.com/Shougo/ddu-ui-ff) で「今開いているソースを取得する方法」があるか調べたものの、見つからなかったのでグローバル変数を使って処理することにしました。

```lua
Caller_source = ""
vim.keymap.set('n', '<leader>gc', function()
  vim.fn['ddu#start']({ name = 'cmdline-history' })
  Caller_source = "cmdline-history"
end)
vim.keymap.set('n', '<leader>gf', function()
  vim.fn['ddu#start']({ name = 'file_rec' })
  Caller_source = "file_recursive"
end)
vim.keymap.set('n', '<leader>gm', function()
  vim.fn['ddu#start']({ name = 'mr' })
  Caller_source = "mr"
end)

vim.api.nvim_create_autocmd("FileType",
  {
    pattern = "ddu-ff",
    callback = function()
      vim.keymap.set("n", "q", [[<Cmd>call ddu#ui#do_action("quit")<CR>]], { buffer = true })
      vim.keymap.set("n", "<CR>", [[<Cmd>call ddu#ui#do_action("itemAction")<CR>]], { buffer = true })
      vim.keymap.set("n", "a", [[<Cmd>call ddu#ui#do_action('chooseAction')<CR>]], { buffer = true })
      vim.keymap.set("n", "i", [[<Cmd>call ddu#ui#do_action("openFilterWindow")<CR>]], { buffer = true })
      if Caller_source == "cmdline-history" then
        vim.keymap.set("n", "e", [[<Cmd>call ddu#ui#do_action("itemAction", {'name': 'edit'})<CR>]], { buffer = true })
        vim.keymap.set("n", "dd", [[<Cmd>call ddu#ui#do_action("itemAction", {'name': 'delete'})<CR>]], { buffer = true })
      end
    end,
  }
)
```

## KindOptions の設定場所

これはテクニックではなく気付いたことですが、ソースに応じた `kindOptions` を設定するため以下のとおり設定しても設定が反映されない場合があります。

```lua
vim.fn["ddu#custom#patch_local"]("source_name", {
  kindOptions = {
    source_name = {
      defaultAction = "execute"
    }
  }
})
```

こうなる原因は不明ですが、対応策としては、`patch_local` に設定するのではなく `patch_global` に設定すればOKです。ソース名を指定することでソース特有の設定になるはずなので、`patch_global` に書いていても実質的には `patch_local` に書いているのと同じになるはずです。

```lua
vim.fn["ddu#custom#patch_global"]({
  kindOptions = {
    source_name = {
      defaultAction = "execute"
    }
  }
})
```

この方法を採用しないと設定が反映されなかった source は以下のとおりです。他にもあるかもしれませんが、`patch_global` に設定している `defaultAction` をデフォルトアクションにしている source については調べていないので不明です。

- [4513ECHO/ddu-source-source: 📜 ddu source source for ddu.vim](https://github.com/4513ECHO/ddu-source-source)
- [Shougo/ddu-source-action: Action source for ddu.vim](https://github.com/Shougo/ddu-source-action)
- [4513ECHO/ddu-source-colorscheme: 🎨 Colorscheme source for ddu.vim](https://github.com/4513ECHO/ddu-source-colorscheme)

