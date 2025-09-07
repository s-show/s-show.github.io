---
title: Neovim の小技集 - モード判定からカラーハイライトまで # Title of the blog post.
date: 2025-09-05T00:00:01+09:00 # Date of post creation.
featured: false
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: true
usePageBundles: false # Set to true to group assets like images in the same folder as this post.
featureImage: '' # Sets featured image on blog post.
featureImageAlt: '' # Alternative text for featured image.
figurePositionShow: true # Override global value for showing the figure label.
tags: [Neovim]
archives: 2025/09
comment: true # Disable comment if false.
---

この記事は、[Vim 駅伝](https://vim-jp.org/ekiden/) の 2025-09-05 の記事です。前回の記事は Atusy さんの [モノリポだっていけちゃうdenols/ts_ls共存術（Neovim >= 0.11） | Atusy's blog](https://blog.atusy.net/2025/09/03/node-deno-decision-with-monorepo-support/) です。

さて、本記事では、私が開発している [ft-mapper.nvim](https://github.com/s-show/ft-mapper.nvim) の改修中に発見したテクニックや、vim-jp コミュニティで共有された情報を備忘録としてまとめます。

## 現在のモードを取得する方法

`vim.api.nvim_get_mode()` で現在のモードを取得することができます。それぞれのモードと返り値の関係は以下のとおりです。

- ノーマルモード       -> `{ blocking = false, mode = "n" }`
- ヴィジュアルモード   -> `{ blocking = false, mode = "v" }`
- オペレータ待機モード -> `{ blocking = false, mode = "no" }`

この機能を使うと、`vim.keymap.set({ 'n', 'v', 'o' }, '<leader>ga', function() ... end)` というキーマッピングで、オペレータ待機モードとそれ以外のモードで処理を分けることができます。具体的には、以下のように実装できます：


```lua
vim.keymap.set({ 'n', 'v', 'o' }, '<leader>ga', function()
  local current_mode = vim.api.nvim_get_mode().mode
  if vim.fn.match(current_mode, 'o') ~= -1 then
    -- オペレータ待機モードの場合の処理
    print("Operator-pending mode")
  else
    -- ノーマルモードまたはビジュアルモードの場合の処理
    print("Normal or Visual mode")
  end
end)
```

[ft-mapper.nvim](https://github.com/s-show/ft-mapper.nvim) では、上記の方法でオペレータ待機モードのときだけ特別な処理を挟むようにしています。

## 最後に実行されたオペレータのコマンドを取得する方法

`vim.v.operator` で、直近に実行されたオペレータを取得できます。

`diw` を実行すると `d` が変数に格納され、`ci(` を実行すると `c` が変数に格納されます。ただし、変数の値が更新されるのは「次のオペレータが実行されたとき」である点に注意が必要です。例えば、`diw` を実行してからノーマルモードで `f[` と操作しても、`vim.v.operator` の値は `d` のままとなります。つまり、この変数に値が格納されているからといって、オペレータ待機モードに入っていると判断することはできません。

そのため、モード判定には前述の `vim.api.nvim_get_mode()` を使用する必要があります。


## カラーコードをそのカラーでハイライトする方法

Neovim v0.12 から導入される `vim.lsp.document_color.enable()` を使用すると、LSP のハイライト機能を利用して `#FFFFFF` や `whitesmoke` といったカラーコードを、実際の色でハイライト表示できるようになります。

この機能は [PR #33440](https://github.com/neovim/neovim/pull/33440) で実装され、[公式ドキュメント](https://neovim.io/doc/user/lsp.html#lsp-document_color)でも紹介されています。v0.12 の [リリースノート](https://github.com/neovim/neovim/blob/9269a1da355b760f5da66a5d2ee7eaad7399848d/runtime/doc/news.txt#L206)にも記載されており、正式版として提供される予定です。

この機能により、[nvim-colorizer.lua](https://github.com/norcalli/nvim-colorizer.lua) のような外部プラグインを必要とする場面が減少します。

### 使い方

この機能は、記事執筆時点（2025年8月）では Nightly 版でのみ利用できます（安定版の v0.11 では利用できないため）。設定は簡単で、設定ファイルで `vim.lsp.document_color.enable()` を呼び出すだけです。

### オプション

`vim.lsp.document_color.enable()` は以下の3つのオプションを指定できます。

- `enable`: 機能の有効/無効を指定（デフォルト: `true`）
- `bufnr`: 対象バッファを指定。`0` で現在のバッファ（デフォルト: `0`）
- `opts`: ハイライトスタイルを指定

利用可能なハイライトスタイルは以下の3種類です：

```lua
-- 背景色でハイライト
vim.lsp.document_color.enable(true, 0, { style = 'background' })
```

{{< bsimage src="./images/screenshot_background.png" title="style = background の場合の表示" >}}

```lua
-- 文字色でハイライト
vim.lsp.document_color.enable(true, 0, { style = 'foreground' })
```

{{< bsimage src="./images/screenshot_foreground.png" title="style = foreground の場合の表示" >}}

```lua
-- VSCode風の四角形アイコンを表示
vim.lsp.document_color.enable(true, 0, { style = 'virtual' })
```

{{< bsimage src="./images/screenshot_virtual.png" title="style = virtual の場合の表示" >}}

### 下位互換性の確保

複数バージョンの Neovim で同じ設定ファイルを使用する場合、`pcall` を使用してエラーを回避できます。

```lua
-- 古いバージョンでもエラーが発生しない
local ok, _ = pcall(vim.lsp.document_color.enable, true, 0, { style = 'virtual' })
```

## まとめ

大した内容ではありませんが、知っていて損はないと思う情報だと思いましたので、備忘録としてまとめました。

参考になれば幸いです。

