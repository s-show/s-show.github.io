---
# type: docs 
title: Neovim で skkeleton を使う方法
date: 2024-06-29T23:05:17+09:00
featured: false
draft: false
comment: true
tags: [vim,neovim]
---

## 前置き

[この記事](https://kankodori-blog.com/posts/2024-06-29/)に続く Neovim の設定に関する記事です。今回は、Vim/Neovim 専用の日本語入力プラグインである [vim-skk/skkeleton: SKK implements for Vim/Neovim with denops.vim](https://github.com/vim-skk/skkeleton) の設定に関する情報を備忘録としてまとめます。

## 環境

### OS

```
エディション	Windows 11 Pro
バージョン	23H2
インストール日	2022/07/11
OS ビルド	22631.3807
エクスペリエンス	Windows Feature Experience Pack 1000.22700.1020.0
```

### Neovim

```cmd
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

## 準備

### 関連するランタイムなどのインストール

skkeleton は Javascript/Typescript ランタイムの1つである [Deno](https://deno.com/) に依存していますので、まず Deno をインストールします。

公式サイトに記載されているインストール方法（Windows版）は、コマンドプロンプトで `irm https://deno.land/install.ps1 | iex` コマンドを実行するという方法ですが、私は Github の [Releases](https://github.com/denoland/deno/releases) で配布されている `.msi` をダウンロードしてインストールしました。


{{% alert info %}}
この方法にした理由は、後述するエラー対応の際、インストールの問題でエラーが起きているのかと思ったため、インストーラーを使ってインストールした方が良いだろうと思ったためです。
{{% /alert %}}

これで Deno をインストールできましたが、skkeleton は、Deno を利用して Vim/Neovim 双方で動くプラグインを作るためのエコシステムである [denops.vim](https://github.com/vim-denops/denops.vim?tab=readme-ov-file) を利用して作成されていますので、denops.vim もインストールします。

denops.vim は、`'C:\Users\(username)\AppData\Local\nvim\lua\plugins\denops.lua'` ファイルを作成して以下の設定を追記し、`:Lazy` コマンドを実行してインストールします。

```lua
return {
  "vim-denops/denops.vim",
  lazy = false,
  priority = 500,
  --config = true,
}
```

### 辞書のインストール

SKK の変換に必要な辞書を [SKK dictionary files gh-pages | dict](https://skk-dev.github.io/dict/) からダウンロードします。保存場所は自由に決められます。私は `C:\skk` ディレクトリに以下の辞書を保存しました。

- SKK-JISYO.L
- SKK-JISYO.jinmei
- SKK-JISYO.geo
- SKK-JISYO.propernoun
- SKK-JISYO.law

## 設定

これで必要なランタイムや辞書はインストールできましたので、`init.lua` に設定を追加します。

```lua
vim.api.nvim_set_keymap('i', '<C-j>', '<Plug>(skkeleton-enable)', {noremap = true})
vim.api.nvim_set_keymap('c', '<C-j>', '<Plug>(skkeleton-enable)', {noremap = true})
vim.api.nvim_set_keymap('i', '<C-l>', '<Plug>(skkeleton-disable)', {noremap = true})
vim.api.nvim_set_keymap('c', '<C-l>', '<Plug>(skkeleton-disable)', {noremap = true})
vim.fn['skkeleton#config']({
  globalDictionaries = {
    "C:/skk/SKK-JISYO.L",
    "C:/skk/SKK-JISYO.geo",
    "C:/skk/SKK-JISYO.jinmei",
    "C:/skk/SKK-JISYO.lisp",
    "C:/skk/SKK-JISYO.law",
  },
  eggLikeNewline = true,
  keepState = true,
  showCandidatesCount = 2,
  registerConvertResult = true,
})
vim.fn['skkeleton#register_keymap']('input', '/', 'abbrev')
```

上の設定は、以下の動作を実現するための設定です。

- `vim.api.nvim_set_keymap( ~~~ )`
  - `ctrl-j` で skkeleton を有効化する（かな入力をオンにする）
  - `ctrl-l` で skkeleton を無効化する（かな入力をオフにする）
- `globalDictionaries = { ~~~ }`
  - 辞書は `C:/skk` ディレクトリに保存しているものを使う（フルパスで指定する）
- `eggLikeNewLine = true`
  - 変換候補を選んで Enter キーをタイプしたときに確定のみ行う（`false` にすると改行される）
- `keepState = true`
  - Insert Mode を抜けても skkeleton の有効/無効の状態を保持する
- `showCandidatesCount = 2`
  - 2回目までの変換では複数の変換候補を表示しない
- `registerConvertResult = 2`
  - カタカナ変換等の結果を辞書に登録する
- `vim.fn['skkeleton#register_keymap']('input', '/', 'abbrev')`
  - `/` で abbrev モードに入る

{{% alert info %}}

追記1

上記の `registerConvertResult = 2` は、正しくは `registerConvertResult = true` です。

また、上記で設定した `vim.fn['skkeleton#register_keymap']('input', '/', 'abbrev')` については、あまり使い道がなかったので、2024年7月時点では設定を削除しています。

さらに、辞書の保存場所を `C:\Users\(username)\AppData\Local\nvim\skk_dict\` に変えましたが、`globalDictionaries` に辞書のパスをハードコードするのはイマイチだと感じましたので、Vim の `expand()` 関数を使ってパスを展開することにしました。

```lua
    vim.fn["expand"]('~/AppData/Local/nvim/skk_dict/SKK-JISYO.L'),
    vim.fn["expand"]('~/AppData/Local/nvim/skk_dict/SKK-JISYO.geo'),
    vim.fn["expand"]('~/AppData/Local/nvim/skk_dict/SKK-JISYO.jinmei'),
    vim.fn["expand"]('~/AppData/Local/nvim/skk_dict/SKK-JISYO.law'),
```

{{% /alert %}}



## 補足

skkeleton の導入の説明は以上のとおりですが、動かせるようになるまでかなり苦戦しました。

と言いますのも、`ctrl-j` で skkeleton を有効化しようとするとエラーが発生して有効化できないという状態が続いたためです。

エラーの様子は以下のスクリーンショットのとおりで、エラーメッセージで検索しても類似の事案が見当たらず、公式リポジトリの Issues にもそれらしい症状がありませんでした。なお、Neovim 起動時にもエラーが表示されていました。

{{< bsimage src="./error1.png" title="ctrl-j を押した時のエラー" >}}
{{< bsimage src="./error2.png" title="Neovim 起動時のエラー" >}}

起動時のエラーから denops のトラブルだと当たりを付けて `:checkhealth`  で問題の有無を調べましたが、問題はなさそうでした。そこでDeno を再インストールしたり、Deno のモジュールの [@std/path - JSR](https://jsr.io/@std/path) をインストールしたり、さらにNeovim のバージョンを変えたりしたのですが解決できなかったので、Slack に用意された Vim-jp のチャットルームで相談しました。

すると `:mes` コマンドで表示されるエラーメッセージの全文を見せて欲しいと言われましたので、Neovim を再起動して `:mes` を実行してエラーメッセージの全文を確認したところ、「Deno のキャッシュに問題があるから `call denops#cache#update(#{reload: v:true})` を実行して Neovim を再起動せよ」と書いてありました。

```
[denops] ********************************************************************************
[denops] Deno module cache issue is detected.
[denops] Execute 'call denops#cache#update(#{reload: v:true})' and restart Vim/Neovim.
[denops] See https://github.com/vim-denops/denops.vim/issues/358 for more detail.
[denops] ********************************************************************************
[denops] Failed to load plugin 'skkeleton': TypeError: Could not find constraint in the list of versions: @std/assert@^0.226.0
[denops]   Specifier: jsr:/@std/assert@^0.226.0/assert
[denops]     at https://jsr.io/@std/path/0.225.2/windows/join.ts:4:24
```

そこで `call denops#cache#update(#{reload: v:true})` を実行して Neovim を再起動したところ、見事にエラーが発生しなくなりました。エラーの原因は Deno のキャッシュだったようですが、Slack の Vim-jp のチャットルームでも Deno のキャッシュ周りで色々トラブルが起きているという発言がありましたので、同じトラブルに巻き込まれてしまったようです。

{{% alert info %}}

追記2

このトラブルですが、WindowsTerminal + NuShell ではトラブルが続いているのに対し、WindowsTerminal + PowerShell では全く発生しません。原因は不明です。

{{% /alert %}}

## SKK を使う理由

わざわざ SKK を使っている理由ですが、まず、文節区切りをユーザーが指定するという一手間が必要なものの、変換不要な平仮名入力では確定作業が不要なため、慣れればサクサク入力できるところに魅力を感じて使っています。文節区切りをユーザーが指定する手間についても、結局「漢字から平仮名に移り変わる部分を指定するだけ」と考えれば大した手間ではありません。

とはいえ、これだけならプラグインを導入しなくても Windows で動く SKK の [corvusskk](https://github.com/nathancorvussolis/corvusskk) を導入すれば良い話で、Neovim 以外のアプリでは corvusskk を使っています。それでも skkeleton を使うのは、Vim/Neovim と IME の相性問題を解消するためです。

プラグインを使わなくても IME の状態を取得・変更できる外部アプリを使えば Vim/Neovim と IME の相性問題は解消できます。実際、以前 Vim を使っていたときはそうしたアプリを Vim から呼び出して IME のオン・オフを制御していました。

しかし、MS-IME を使う場合はこの方法で対応できますが、corvusskk を使う場合はダメでした。理由は、MS-IME だと「Normal Mode に入ったら IME オフ、Insert Mode に入ったら前回の Insert Mode での IME のオン・オフの状態を復元する」という制御で足りるのに対し、corvusskk では Insert Mode に入ったときに IME のオン・オフに加えて入力モードも復元する必要があり、その方法を見つけられなかったためです。

そのため、Vim/Neovim のプラグインとして提供されている SKK なら IME との相性問題を解決できるだろうと思い skkeleton を使うことにしました。
