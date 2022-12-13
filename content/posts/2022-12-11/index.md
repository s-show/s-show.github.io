---
# type: docs 
title: WSL2 + Neovim + VSCode でIME の状態を制御する方法
date: 2022-12-11T21:26:56+09:00
featured: false
draft: false
comment: true
toc: false
tags: [備忘録]
images: []
---

## 前置き

これまでいくつかのエディタを使ってきましたが、Vim のキーバインドが使えると何かと楽、というよりも Vim のキーバインドに手が慣れているため、思い切って Neovim を使ってみることにしました。

ただ、必要に応じて VSCode も使えるようにしたいので、VSCode のプラグインの [vscode-neovim/vscode-neovim: Vim-mode for VS Code using embedded Neovim](https://github.com/vscode-neovim/vscode-neovim) もインストールして、VSCode と Neovim を統合することにしました。

そのために現在進行形で色々と設定していますので、備忘録として設定内容をメモしていきます。

## 今回実現したいこと

インサートモードでの IME の状態を記憶しておいて、ノーマルモードに戻ってから再度インサートモードに入ったときに、従前の IME の状態を復元するというものです。

つまり、インサートモードで IME をオンにして日本語を編集し、そこから `esc` キーでノーマルモードに戻ったら IME をオフにしてキー操作に備え、再びインサートモードに入ったら IME の状態を復元（＝IME オン）するというものです。

この機能を実現したい理由は、私がエディタで編集する文書の多くが日本語の文章なので、インサートモードで選択した IME の状態を、再びインサートモードに入ったときに復元できると作業効率が大幅にアップするためです。

ノーマルモードに戻ったときに IME を自動的にオフにする方法はすぐに見つかったのですが、インサートモードで選択していた IME の状態を復元する方法は中々見つからなかったため、その方法をメモします。

## 環境

```
# Powershell
$ wsl --version
WSL バージョン: 1.0.3.0
カーネル バージョン: 5.15.79.1
WSLg バージョン: 1.0.47
MSRDC バージョン: 1.2.3575
Direct3D バージョン: 1.606.4
DXCore バージョン: 10.0.25131.1002-220531-1700.rs-onecore-base2-hyp
Windowsバージョン: 10.0.22621.900
```

```bash
# WSL2
$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 20.04.5 LTS
Release:        20.04
Codename:       focal

$ nvim --version
NVIM v0.8.1
Build type: Release
LuaJIT 2.1.0-beta3
Compiled by linuxbrew@43b3775c8372
```

## 使った外部ツール

Neovim 自体に IME の状態取得や切り替え機能は備わっていませんので、IME の状態取得や切り替えは外部ツールを使う必要があります。

私が使ったのは [kaz399/spzenhan.vim](https://github.com/kaz399/spzenhan.vim) というツールです。このツールは、引数無しで実行すると IME の状態（IME ON → 1, IME OFF → 0）を返し、引数に `1` か `0` を渡すと IME をオン・オフしてくれるというものです。

このツールは [iuchim/zenhan](https://github.com/iuchim/zenhan) から Fork して開発されたツールですが、zenhan が備えている IME の切り替え機能に現在の IME の状態を取得する機能が追加されているため、今回採用しました。

## 手順

### ツールのインストール

まず、`git clone [git@github.com](mailto:git@github.com):kaz399/spzenhan.vim.git` コマンドで spzenhan.vim をインストールします。

### パスの設定

私はシェルに fish を使っているため、 `set -Ux fish_user_paths $HOME/spzenhan.vim/zenhan/ $fish_user_paths` コマンドでツールへのパスを通しました。これで `spzenhan.exe` コマンドで IME の状態取得や制御ができるようになります。使用結果は次のとおりです。

```bash
# IME ON の時
$ spzenhan.exe
1
# IME Off の時
$ spzenhan.exe
0

$ spzenhan.exe 1 # IME Off -> On
$ spzenhan.exe 0 # IME On -> Off
```

## init.vim の設定

以下のコードを `init.vim` に追加します。

```
" IME制御の設定
command! ImeOff silent !spzenhan.exe 0
command! ImeOn  silent !spzenhan.exe 1

function! ImeAutoOn()
    if !exists('b:ime_status')
        let b:ime_status=0
    endif
    if b:ime_status==1
        :silent ImeOn
    endif
endfunction

function! ImeAutoOff()
    let b:ime_status=system('spzenhan.exe')
    :silent ImeOff
endfunction

" IME off when in insert mode
augroup InsertHook
    autocmd!
    autocmd InsertEnter * call ImeAutoOn()
    autocmd InsertLeave * call ImeAutoOff()
augroup END
```

コードの内容を解説しますと、`command!` で IME のオンオフを切り替える `ImeOff` と `ImeOn` という[ユーザー定義コマンド](https://vim-jp.org/vimdoc-ja/map.html#user-commands)を作成し、それをインサートモードに入ったとき（`autocmd InsertEnter`）とインサートモードを抜けるとき（`autocmd InsertLeave`）に `ImeAutoOn()`, `ImeAutoOff()` 関数経由で実行しています。

`ImeAutoOff` 関数では `let b:ime_status=system('spzenhan.exe')` で spzenhan.exe を引数無しで実行して IME の状態を取得して変数に格納しています。この変数を `ImeAutoOn` 関数で使用することで、インサートモードを抜けるときの IME の状態を復元しています。

---

## 参考にしたサイト

- [【FreeBSD】Vim/Neovimで挿入モード遷移時に前回のIME状態をセットする(uim-fep/fcitx) - HacoLab](https://hacolab.hatenablog.com/entry/2020/01/15/194928)
- [VSCodeでもnormal移行時に英数IMEに切り替えたい - GitPress.io](https://gitpress.io/@mimori37/VSCode%E3%81%A7%E3%82%82normal%E7%A7%BB%E8%A1%8C%E6%99%82%E3%81%ABIME%E5%88%87%E3%82%8A%E6%9B%BF%E3%81%88%E3%81%9F%E3%81%84)

