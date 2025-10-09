---
title: Quickfix を Fuzzy Finder やバッファ管理などの UI として使う方法 # Title of the blog post.
date: 2025-10-08T00:00:00+09:00 # Date of post creation.
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

この記事は [Vim 駅伝](https://vim-jp.org/ekiden/) の 2025/10/08 の記事です。
前回の記事は mityu さんの[「Vim/Neovim で grep 前にディレクトリの確認を入れると便利」](https://zenn.dev/vim_jp/articles/vim-check-path-before-grep) でした。

## きっかけ

Reddit から日に数回飛んでくる注目ポストのメールを見ていたところ、Vim の Quickfix と [fd](https://github.com/sharkdp/fd) と [fzf](https://github.com/junegunn/fzf) を組み合わせてプラグインなしで Fuzzy Finder の機能を実装するという取り組みが紹介されていました。

Fuzzy Finder には [snacks.nvim](https://github.com/folke/snacks.nvim) と [ddu.vim](https://github.com/Shougo/ddu.vim/) を使っているのですが、プラグインを減らせるのは魅力的なので、早速真似してみることにしまさいた。

元記事は fd と fzf を使っていますが、プラグインに加えて外部ツールも減らしたかったので、AI の力も借りて、Quickfix を「ファイル検索・ファイルの曖昧検索・バッファリスト管理・grep」の UI として利用し、さらに外部ツールなしでもこれらの機能を利用できるようにしました。

なかなかイイ感じになりましたので、誰かの参考になればと思い紹介します。

## 実装した動作

### ファイル検索

`:Findqf` コマンドを新規に作成し、このコマンドに検索したい文字列を引数で渡すと、fd がインストールされていれば fd で検索した結果が Quickfix に表示され、fd がインストールされていなければ Neovim 標準の `:find` の検索結果が Quickfix に表示されます。また、検索結果にカーソルを合わせると右側にプレビューが表示されます。

なお、検索をスピーディーにするため、`.git` などのディレクトリは検索しない設定にしています。

{{< video src="https://github.com/s-show/s-show.github.io/raw/refs/heads/main/content/post/2025-10-08/images/findqf.mp4" type="video/webm" preload="auto" >}}

### ファイルの曖昧検索

`:Fzfqf()` コマンドに曖昧検索したい文字列を引数で渡すと、曖昧検索でヒットしたファイルのリストを Quickfix に表示します。曖昧検索自体のアルゴリズムと順位付けのアルゴリズムは特別に組んでいますので、fzf が無くても動作します。検索結果にカーソルを合わせると右側にプレビューが表示されます。

順位付けのルールは以下のとおりです。

1. **完全一致**: クエリとファイル名が完全に一致（`query: mini`, `text: mini`）
2. **前方一致**: ファイル名またはパスセグメントの先頭から一致（`query: mini`, `text: home/nvim/lua/plugins/mini-ai.lua`）
3. **部分文字列**: ファイル名の任意の位置で連続して一致（`query: mini`, `text: home/nvim/lua/plugins/nvim_mini.lua`）
4. **サブシーケンス**: 文字が順番通りに出現（連続でなくても可）（`query: mini`, `text: home/nvim/lua/plugins/ddu-source-cmdline_history.lua`）

同一カテゴリー内では、正規化レーベンシュタイン距離でソートすることで、より自然な検索結果を実現しています。

こちらも検索をスピーディーにするため、`.git` などのディレクトリは検索しない設定にしています。

{{< video src="https://github.com/s-show/s-show.github.io/raw/refs/heads/main/content/post/2025-10-08/images/fzfqf.mp4" type="video/webm" preload="auto" >}}

### バッファリスト

`:ls` コマンドと `:buffer` コマンドでバッファ移動する代わりに `:Bufqf` コマンドを実行すると、Quickfix にバッファリストが表示されます。バッファリストにカーソルを合わせると右側にプレビューが表示されます。

{{< video src="https://github.com/s-show/s-show.github.io/raw/refs/heads/main/content/post/2025-10-08/images/buffer_list.mp4" type="video/webm" preload="auto" >}}

### grep 検索

`:Grep` コマンドに検索したい文字列と検索場所を引数で渡すと、ヒットしたファイルのリストが Quickfix に表示されます。これは標準の grep にプレビュー機能を追加したものです。

なお、Neovim は ripgrep がインストールされていると ripgrep を自動的に使います。

{{< video src="https://github.com/s-show/s-show.github.io/raw/refs/heads/main/content/post/2025-10-08/images/grep.mp4" type="video/webm" preload="auto" >}}

## 実装

コードは長いのでここに掲載するのはちょっと厳しいです。なので、私のドットファイル管理の[リポジトリ](https://github.com/s-show/dotfiles_nixos/tree/3b3930a93cd82b00898ced14da9619cb5639f0cd/home/nvim/lua/util/quickfix_preview)を見てください。

なお、Fuzzy Finder の順位付け処理は上記の `/lua/util/quickfix_preview` ディレクトリではなく [lua/util/fuzzy_rank.lua](https://github.com/s-show/dotfiles_nixos/blob/3b3930a93cd82b00898ced14da9619cb5639f0cd/home/nvim/lua/util/fuzzy_rank.lua) にあります。他でも使うため、ディレクトリを別にしています。

## 実装した感想

これまでプラグイン頼みだった Fuzzy Finder、バッファ移動、grep 検索をプラグインなしで実行できるようになり、Neovim のカスタマイズの奥深さを知ることができました。

特に、Quickfix は Vim の強力な機能でありながらこれまで使ってこなかったため、その効果に驚いています。

また、その気になれば fd や fzf や ripgrep を使わずにこれだけの機能が実装できると分かったのも大きいです。まだまだ Neovim の改造はできそうです。

## 参考にした記事など

最初のブログ記事がアイデア元で、他は曖昧検索の順位付けをどうするか検討していた際に参考にしたものです。

- [Ditching the Vim fuzzy finder plugin part 1: :find](https://jkrl.me/vim/2025/09/02/nvim-fuzzy-find.html)
- [fuzzy-finder で使われるスコアリングアルゴリズム - blog.syfm](https://syfm.hatenablog.com/entry/2019/01/31/090000)
- [検索クエリからファジーにキーワードを抽出する（スミス・ウォーターマン法に基づく実装） - Giftmall Inside Blog](https://inside.luchegroup.com/entry/2022/12/15/135713)
- [実践力をアップする Pythonによるアルゴリズムの教科書 | マイナビブックス](https://book.mynavi.jp/ec/products/detail/id=138749)

