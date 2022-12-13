---
# type: docs 
title: WSL2 + Neovim でクリップボードを共有する方法
date: 2022-12-12T22:05:21+09:00
featured: false
draft: false
toc: false
comment: true
tags: [備忘録]
images: []
---

## 前置き

昨日の [WSL2 + Neovim + VSCode でIME の状態を制御する方法 - 閑古鳥ブログ](https://kankodori-blog.com/posts/2022-12-11/) に続いて WSL2 + Neovim の設定についてメモしていきます。

今回は、Neovim でヤンクした内容を OS のクリップボードに共有する方法と、OS のクリップボードの内容を Neovim に貼り付ける方法の模索です。

ちなみに、先に申し上げておきますと、今回ご紹介する方法は「現時点では動いている」というものです。色々調べて現在の設定に至っていますが、ある人にとって上手くいく方法が別の人では上手くいかなかったりしているようですので、これからご紹介する方法を真似しても上手くいかないかもしれません。


## 方法

### win32yank.exe のインストール

まず、WSL2 上の Neovim と Windows 側のクリップボードの橋渡しをするアプリが必要なため、公式の [FAQ](https://github.com/neovim/neovim/wiki/FAQ#how-to-use-the-windows-clipboard-from-wsl) を参考に `win32yank.exe` をインストールします。

Windows 側と WSL2 の両方に Neovim をインストールしている場合と WSL2 のみにインストールしている場合で手順が異なりますが、私は WSL2 にのみ Neovim をインストールしているため、次のコマンドで `win32yank.exe` をインストールしました。

```bash
curl -sLo/tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
unzip -p /tmp/win32yank.zip win32yank.exe > /tmp/win32yank.exe
chmod +x /tmp/win32yank.exe
sudo mv /tmp/win32yank.exe /usr/local/bin/
```

### init.vim の設定その1

公式の [FAQ](https://github.com/neovim/neovim/wiki/FAQ#how-to-use-the-windows-clipboard-from-wsl) では、`init.vim` に `set clipboard=unnamedplus` を追加すれば Neovim がデフォルトでシステム側のクリップボードを使うようになると書かれています。しかし、私の環境でこの設定を追加すると希望通りの動作にならなかったため、`set clipboard=unnamed` という設定に変更しました。

この `set clipboard=` の設定は人によって説明がまちまちで、`set clipboard=unnamedplus`、`set cilpboard+=unnamedplus`、さらに `set clipboard=unnamed` にと色々なパターンがあるようです。私の場合、3つ試して `set clipboard=unnamed` で上手くいきました。

### init.vim の設定その2

最初は `set clipboard=unnamedplus` を追加すれば Neovim でヤンクした内容が OS のクリップボードにコピーされましたが、[vscode-neovim/vscode-neovim: Vim-mode for VS Code using embedded Neovim](https://github.com/vscode-neovim/vscode-neovim) をインストールした VSCode では、ヤンクした内容がクリップボードにコピーされませんでした。

そこで同様の症状に遭遇した人がいるか調べたところ、vscode-neovim の Issues（[WSL visual yank to clipboard](https://github.com/vscode-neovim/vscode-neovim/issues/761)） で同じ症状に遭遇した人がいて、その方は `clip.exe` を使う設定を追加して問題を解決していました。

それから、`win32yank.exe`  を使う方法を紹介しているこちらの記事 ([Neovim on WSL2で、win32yankを導入してクリップボードの共有と遅延問題を解決](https://zenn.dev/shoseisan/articles/d7565884f5846b)) と Reddit のこの投稿（[Solution! Neovim clipboard with WSL](https://www.reddit.com/r/neovim/comments/g94zrl/comment/forqemn/?utm_source=share&utm_medium=web2x&context=3)） も発見しましたので、これらの記事で紹介されている設定を追加したところ、VSCode でもヤンクした文字列がクリップボードにコピーされるようになりました。

以上の設定をまとめると、次のとおりとなります。

```vim
" ヤンクでWindowsのクリップボードを使う
set clipboard=unnamed
let g:clipboard = {
\   'name': 'WslClipboard',
\   'copy': {
\      '+': 'win32yank.exe -i --crlf',
\      '*': 'win32yank.exe -i --crlf',
\    },
\   'paste': {
\      '+': 'win32yank.exe -o --lf',
\      '*': 'win32yank.exe -o --lf',
\   },
\   'cache_enabled': 0,
\ }
```

これらの設定を追加することで、ブラウザなどでクリップボードにコピーした内容を Neovim に `p` キーで貼り付けられるようになりました。

ただし、`nvim .` コマンドで Neovim を起動すると、なぜか直前にコピーした内容と異なる内容が貼付けされてしまいます。この症状を解消すべく試行錯誤しましたが解決できませんでしたので、現在は `nvim` コマンドで Neovim を起動するようにしています。

## 補足

私が使っている win32yank.exe ですが、公式リポジトリの Issues にはクラッシュなどの報告が結構見受けられます。私の環境でも、WindowsTerminal で Neovim を動かしてコピペして編集していますと、たまに WindowsTerminal がクラッシュしますので、その点は注意が必要だと思います。

