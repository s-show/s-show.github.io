---
# type: docs 
title: Neovim の LSP 設定を見直してエラー表示を解消した話
date: 2024-10-14T18:04:45+09:00
featured: false
draft: false
comment: true
toc: false
tags: [neovim,vim]
---

## 前置き

Neovim で C言語の LSP を設定した上で自作キーボードのファームウェアの QMK Firmware（大半のコードがC言語） を編集しているのですが、下のスクリーンショットのとおり大量の "unknown type name" とか "call to undeclare" エラー表示が出ていました。

{{< bsimage src="./image/before.png" title="エラーが出ている様子" >}}

エラー表示はたくさん出ていますが、ファームウェアはコンパイルできますしキーボードもきちんと動作します。つまり、必要な型定義や関数定義はできており、問題はエディタにたくさんのエラーが出て精神衛生上よろしくないという問題に過ぎないのですが、思い切って対応することにしました。

## 対応策

結論から言いますと、プロジェクトのルートディレクトリに `compile_commands.json` が存在しなかったのが原因でした。

この `compile_commands.json` を QMK Firmware の `qmk generate-compilation-database` コマンドで作成したところ、下のスクリーンショットのとおり "unknown type name" とか "call to undeclare" エラー表示が消えました。

{{< bsimage src="./image/after.png" title="エラーを解消した様子" >}}

解決に至るまでの過程を説明しますと、まず、この問題を Slack の vim-JP で相談したら LSP の [clangd](https://clangd.llvm.org) の設定の問題ではないかとアドバイスされました。そこで[公式リファレンス](https://clangd.llvm.org/installation) を確認したところ、"Neovim built-in LSP client" を使っている場合の設定方法が以下のとおり記載されていましたので、まずその設定を追加しました。

```lua
local lspconfig = require('lspconfig')
lspconfig.clangd.setup({
  cmd = {'clangd', '--background-index', '--clang-tidy', '--log=verbose'},
  init_options = {
    fallbackFlags = { '-std=c++17' },
  },
})
```

次に、公式リファレンスでは clangd にソースコードを理解させるために `compile_commands.json` を作成するよう書かれていました。そこで `compile_commands.json` を作成しようとしたのですが、ここでちょっとしたトラブルに遭遇しました。

というのも、QMK Firmware のビルドは `qmk compile` コマンドで実施しており、`make` コマンドなどは使わないのですが、そういう場合の対処方法として、公式リファレンスでは [Bear](https://github.com/rizsotto/Bear) というツールを使うよう指示されていたためです。ただ、この目的のためだけにツールをインストールするのは面倒ですし、このツールが `qmk compile` コマンドを受け付けるかも分からなかったためです。

そこで色々調べていたのですが、ふと QMK Firmware の公式リファレンスの [QMK CLI Commands](https://docs.qmk.fm/cli_commands#qmk-generate-compilation-database) を見たところ、`qmk generate-compilation-database` コマンドで `compile_commands.json` を作成できることが分かりました。そこでこのコマンドを実行したところ、問題なく `compile_commands.json` が作成できてエラー表示を解消することができました。

大した話ではありませんが、誰かの参考になるかもしれませんので、備忘録として記事を作成しました。

## 補足

私は clangd を [mason.nvim](https://github.com/williamboman/mason.nvim) でインストールし、[mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) 経由で [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) で設定していますが、nvim-lspconfig が用意している[デフォルト設定](https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/clangd.lua)は clangd の公式リファレンスとある程度同じでした。後で上記の設定を削除してみましたがエラー表示の状況は同じでしたので、エラー表示の解消のためだけなら上記の設定は不要かもしれません。ただ、上記の設定はログのトレースや追加機能を使うための設定とのことなので、設定しても無駄にはならないかと思います。

