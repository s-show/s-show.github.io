---
# type: docs 
title: 2023 01 02
date: 2022-12-31T21:18:15+09:00
featured: false
draft: true
comment: true
toc: true
tags: []
images: []
---

## 前置き

2022年12月25日の記事で Neovim の設定を色々紹介しましたが、そこで設定コードだけ紹介した [新世代の UI 作成プラグイン ddu.vim](https://zenn.dev/shougo/articles/ddu-vim-beta) について、もう少し詳しく解説したいと思います。

## プラグインの説明

ddu.vim 自体の説明は作者の方のこの記事 → [新世代の UI 作成プラグイン ddu.vim](https://zenn.dev/shougo/articles/ddu-vim-beta) に詳しい説明がありますが、ファジーファインダーとして開発されたプラグインで、ddu.vim 自体はフレームワークの提供に特化し、UI 構築やデータソース取得といった機能は別のプラグインに任せるという点が大きな特徴です。

そのため、このプラグインだけインストールしても使うことはできず、次のプラグインもインストールする必要があります。

1. UI 担当のプラグイン
1. 操作対象となるデータを取得してくるプラグイン
1. データのソート、マッチング、フィルタリングを担当するプラグイン
1. データに対する各種操作

そして、ddu.vim にこれらのプラグインを組み合わせて使っていくこととなります。一見するとかなり面倒なプラグインという印象を受けますが、次の点が大きなメリットとなります。

まず、UI を専用のプラグインが担当しますので、自分の好きな UI を構築できます。もちろん UI 構築は大変（私には無理）ですが、ddu.vim をファイラーとして使う場合、現時点でも作者がファイラーの UI として作成した [Shougo/ddu-ui-filer: File listing UI for ddu.vim](https://github.com/Shougo/ddu-ui-filer) とファジーファインダーの UI として作成した [Shougo/ddu-ui-ff: Fuzzy finder UI for ddu.vim](https://github.com/Shougo/ddu-ui-ff) の2つの UI を使えます。ツリー表示が好みなら ddu-ui-filer を選びますし、多数のファイルから条件に合うファイルをピックアップする形が好みなら ddu-ui-ff を選ぶことになります。

それから、操作対象となるデータの取得やソートなどを行うプラグインも自分で選びますので、不要なデータはそもそも取得しないといった設定も可能です。取得できるデータは、ファイルやバッファのリストなどに加えて、レジスタやWindowsのクリップボードの履歴といったものもあります。

このように自由度が高く自分の好みに合わせられるプラグインですが、やりたいことから設定を逆引きできるようなドキュメントは見当たらないため、設定作業が難しいのは事実だと思います。かくいう私も、このプラグインをファイラー＆バッファリスト絞り込み＆コマンド履歴絞り込みに使っていますが、しばらくすると設定方法を忘れてしまいそうなので、将来の自分のためにも設定方法をまとめようと思います。


## 設定の流れ

大まかな設定の流れは次のとおりです。

1. Deno のインストール
1. denops.vim のインストール
1. ddu.vim のインストール
1. UI 用プラグインなどのインストール
1. 設定作業

### Deno のインストール

ddu.vim は Deno を使って開発されていますので、[公式サイト](https://deno.land/) の Installation を参照して Deno をインストールします。私の場合、Neovim を WSL2 にインストールしていますので、次のコマンドでインストールしました。

```bash
curl -fsSL https://deno.land/x/install/install.sh | sh
```

それから次のコマンドでパスを通します。なお、私はシェルに [fish shell](https://fishshell.com/) を使っています。

```bash
set -Ux fish_user_paths /home/s-show/.deno/bin/ $fish_user_paths
```

そして、次のコマンドで正しくインストールできたか確認します。

```bash
> deno --version
deno 1.28.3 (release, x86_64-unknown-linux-gnu)
v8 10.9.194.5
typescript 4.8.3
```

### deno.vim のインストール

Deno をインストールしたら、次は Deno を使って Vim/Neovim のプラグインを作成するためのエコシステムである [vim-denops/denops.vim: 🐜 An ecosystem of Vim/Neovim which allows developers to write cross-platform plugins in Deno](https://github.com/vim-denops/denops.vim) をインストールします。

こちらはプラグインであるため、インストールは Neovim 側で行います。私はプラグイン管理に [tani/vim-jetpack: The lightning-fast plugin manager, alternative to vim-plug](https://github.com/tani/vim-jetpack) を使っていますので、次のコードを `init.vim` に追加して `:JetpackSync` コマンドを実行してインストールしています。

```vim
Jetpack 'vim-denops/denops.vim'
```

### ddu.vim と付属プラグインのインストール

これで下準備はできましたので、ddu.vim と UI と source と Filter 機能を提供するプラグイン関連するプラグインをインストールします。

関連するプラグインとしてどのプラグインをインストールするかが問題ですが、ここでは、「ファイラー、バッファリスト管理およびコマンド履歴管理」の3つの機能を実現することとし、かつ、「ファイラーはファイルツリー形式で表示」「バッファリストとコマンド履歴はファジーファインダーで管理」するという方針でインストールするプラグインを決定します。

`init.vim` に以下のコードを追加してから `:JetpackSync` コマンドを実行してプラグインをまとめてインストールします。

```
Jetpack 'Shougo/ddu.vim'
Jetpack 'Shougo/ddu-ui-filer'
Jetpack 'Shougo/ddu-ui-ff'
Jetpack 'Shougo/ddu-source-file'
Jetpack 'Shougo/ddu-source-file_rec'
Jetpack 'Shougo/ddu-source-register'
Jetpack 'kuuote/ddu-source-mr'
Jetpack 'Shougo/ddu-source-command_history'
Jetpack 'Shougo/ddu-commands.vim'
Jetpack 'Shougo/ddu-column-filename'
Jetpack 'shun/ddu-source-buffer'
Jetpack 'Shougo/ddu-filter-matcher_substring'
Jetpack 'Shougo/ddu-kind-file'
```


### ddu.vim の設定

いよいよ ddu.vim を設定していきますが、先にコードを提示し、そのコードについて解説する方が説明が楽なので、まずコードを提示します。

```

```

## hogehoge
