---
# type: docs 
title: Neovim のヘルプを日本語化する
date: 2024-06-29T01:51:48+09:00
featured: false
draft: false
comment: true
toc: true
tags: [vim]
---

## 前置き

私のエディタ遍歴（というほどでもないですが）は、Sublime Text、Atom、Vim、VSCode という感じで、最近は VSCode を使っていました。

しかし、VSCode は多機能で便利な反面、サクラエディタのような高速に起動するものではないため、編集したいと思ったらすぐ起動するエディタを使いたくなってきました。

そこで Neovim を使ってみたところ、起動が早い上、Neovim 専用の SKK プラグインを導入したら日本語編集も簡単になりましたので、しばらく Neovim を使ってみようと思うようになりました。

Neovim を快適に使うためのプラグインの導入や設定変更は現在進行中で進めていますが、完了したものから順次備忘録代わりにメモしていこうと思います。

なお、プラグインは [folke/lazy.nvim: 💤 A modern plugin manager for Neovim](https://github.com/folke/lazy.nvim) で管理しており、lazy.nvim に関する `init.lua` の設定は次のとおりです。プラグインごとに設定ファイルを分割したいので、プラグインの設定ファイルは `'C:\Users\(username)\AppData\Local\nvim\lua\plugins\'` ディレクトリに保存しています。

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup("plugins")
```

## 環境

### OS

```
エディション	Windows 11 Pro
バージョン	23H2
インストール日	‎2022/‎07/‎11
OS ビルド	22631.3807
エクスペリエンス	Windows Feature Experience Pack 1000.22700.1020.0
```

### Neovim

```
❯ nvim --version
NVIM v0.9.4
Build type: RelWithDebInfo
LuaJIT 2.1.1696883897
Compilation: C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise/VC/Tools/MSVC/14.29.30133/bin/Hostx64/x64/cl.exe /MD /Zi /O2 /Ob1  -W3 -wd4311 -wd4146 -DUNIT_TESTING -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_DEPRECATE -D_WIN32_WINNT=0x0602 -DMSWIN -DINCLUDE_GENERATED_DECLARATIONS -ID:/a/neovim/neovim/.deps/usr/include/luajit-2.1 -ID:/a/neovim/neovim/.deps/usr/include -ID:/a/neovim/neovim/.deps/usr/include -ID:/a/neovim/neovim/build/src/nvim/auto -ID:/a/neovim/neovim/build/include -ID:/a/neovim/neovim/build/cmake.config -ID:/a/neovim/neovim/src -ID:/a/neovim/neovim/.deps/usr/include -ID:/a/neovim/neovim/.deps/usr/include -ID:/a/neovim/neovim/.deps/usr/include -ID:/a/neovim/neovim/.deps/usr/include -ID:/a/neovim/neovim/.deps/usr/include -ID:/a/neovim/neovim/.deps/usr/include -ID:/a/neovim/neovim/.deps/usr/include

      システム vimrc: "$VIM\sysinit.vim"
       省略時の $VIM: "C:/Program Files (x86)/nvim/share/nvim"

Run :checkhealth for more info
```

### プラグイン管理

プラグインは [folke/lazy.nvim: 💤 A modern plugin manager for Neovim](https://github.com/folke/lazy.nvim) で管理しており、lazy.nvim にかかる `init.lua` の設定は次のとおりです。プラグインごとに設定ファイルを分割したいので、プラグインの設定ファイルは `'C:\Users\(username)\AppData\Local\nvim\lua\plugins\'` ディレクトリに保存しています。

```
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup("plugins")
```

## ヘルプを日本語化する方法

まず、[vim-jp/vimdoc-ja: A project which translate Vim documents into Japanese.](https://github.com/vim-jp/vimdoc-ja) で配布されている日本語のヘルプファイルを導入します。このヘルプファイルはプラグインとして導入できますので、`'C:\Users\(username)\AppData\Local\nvim\lua\plugins\vimdoc-ja.lua'` ファイルを用意して以下の設定を追加します。

```lua
return {
  {
    "vim-jp/vimdoc-ja",
  },
}
```

それから `:Lazy` コマンドを実行して日本語ヘルプファイルをインストールします。

日本語のヘルプファイルがインストールできましたら、`init.lua` に次の設定を追加して Neovim を再起動します。

```lua
vim.opt.helplang = 'ja'
```

これで `:h hogehoge` とした場合に表示されるヘルプが日本語版になります。

```vim
:h helplang

						*'helplang'* *'hlg'*
'helplang' 'hlg'	文字列	(既定では: メッセージ言語または空)
			グローバル
			{|+multi_lang| 機能つきでコンパイルされたときのみ有効}
	コンマ区切りの言語のリスト。これらの言語の中から、探しているヘルプが見
	つかった最初の言語を使う。英語のヘルプは常に優先度が最後になる。英語の
	優先度を上げるために "en" を追加することはできるが、そうしても、その言
	語に存在し、英語のヘルプに存在しないタグを見つけるだけである。
	{訳注: 上の文よくわからない。}
	例: >
		:set helplang=de,it
<	こうすると最初にドイツ語を検索し、次にイタリア語、そして最後に英語のヘ
	ルプファイルを検索する。
	|CTRL-]| や英語でないヘルプファイル中で ":help!" を使ったときは、この
	オプションより先に現在の言語からタグを検索する。|help-translated| を参
	照。
```
