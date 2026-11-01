---
title: "Lazy.nvim と Neovim のプラグイン読み込み順の違い" # Title of the blog post.
date: 2026-11-01T14:47:59+09:00 # Date of post creation.
featured: true # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: true # Controls if a table of contents should be generated for first-level links automatically.
# menu: main
tags:
  - neovim
  - lazy.nvim
comment: true # Disable comment if false.
archives: 2026/11
---

## 前置き

Neovim の v0.13 で導入された dir という組込みプラグインをカスタマイズしようとしたところ、既存の組込みプラグインの Netrw と衝突するという事態に遭遇しました。

そこで、この衝突の原因を AI の協力を得ながら調べたところ、私が使っているプラグインマネージャーの Lazy.nvim と Neovim のプラグイン読み込み機構に違いがあることが分かりましたので、備忘録として調査結果をまとめます。

なお、dir プラグインが何かと言いますと、Netrw から「ローカルのディレクトリを一覧する」機能を取り出して Lua で書き直したもので、[feat(runtime): directory browser (replace netrw with a very small script) by barrettruth · Pull Request #39723 · neovim/neovim](https://github.com/neovim/neovim/pull/39723) の PR で導入されました。

Netrw は多くの機能を単一の Vim script プラグインで実現していて、その行数は1万行にもなりますので、[Consider removing netrw in favor of dirvish · Issue #4378 · neovim/neovim](https://github.com/neovim/neovim/issues/4378) や [Replace netrw with smaller Lua modules · Issue #32280 · neovim/neovim](https://github.com/neovim/neovim/issues/32280) で機能分割などが提案されていました。dir プラグインはそうした提案を受けて開発されたものです。

## 調査結果

### 結論

結論から書きますと、プラグイン読み込み機構に関する Lazy.nvim と Neovim の違いは以下のとおりです。

- Neovim: `.vim` のプラグインファイルを読み込んでから、`.lua` のプラグインファイルを読み込んでいく。それぞれの読み込み順はアルファベット順。
- Lazy.nvim: `.vim` のプラグインファイルと `.lua` のプラグインファイルを区別せずにアルファベット順に読み込む。Neovim のプラグイン読み込み機構は無効化している。

### 結論の根拠

#### Neovim 側

まず、Neovim のプラグイン読み込み機構については、ヘルプ（load-plugins）で 


> 12. Load the plugin scripts. *load-plugins*
>
> This does the same as: `:runtime! plugin/**/*.{vim,lua}`
> - The result is that all directories in 'runtimepath' will be searched for the "plugin" sub-directory and all files ending in ".vim" or ".lua" will be sourced (in alphabetical order per directory), also in subdirectories. First "\*.vim" are sourced, then "\*.lua" files, per directory.

> （拙訳）
>
> 12.プラグインスクリプトをロードする。 *load-plugins* 
>
>  これは `:runtime! plugin/**/*.{vim,lua}` を実行するのと同様の処理です。
> - その結果、'runtimepath' に含まれるすべてのディレクトリから "plugin" サブディレクトリが検索され、拡張子が ".vim" または ".lua" のすべてのファイルが（各ディレクトリ内でアルファベット順に）実行（source）されます。これにはサブディレクトリ内のファイルも含まれます。ディレクトリごとに、まず ".vim" ファイルが実行され、次に ".lua" ファイルが実行されます。

と説明されています。

Netrw は `runtime/plugin/netrwPlugin.vim` から、dir は `runtime/plugin/dir.lua` からそれぞれ読み込まれますので、dir は Netrw の後に読み込まれます。

#### Lazy.nvim 側

まず、Lazy.nvim は Neovim のプラグイン読み込み機構を無効化します。

```lua
-- ~/.local/share/nvim/lazy/lazy.nvim/lua/lazy/core/config.lua
-- disable plugin loading since we do all of that ourselves
vim.go.loadplugins = false
```

それから Lazy.nvim 独自の方法でプラグインを読み込んでいきますが、その読み込み順はヘルプには記載されていません。ただ、以下に示している実際のコードに

> plugin files are sourced alphabetically per directory

というコメントがありますので、アルファベット順に読み込んでいることが分かります。

```lua
-- ~/.local/share/nvim/lazy/lazy.nvim/lua/lazy/core/loader.lua
---@param ... string
function M.source_runtime(...)
  local dir = table.concat({ ... }, "/")
  ---@type string[]
  local files = {}
  Util.walk(dir, function(path, name, t)
    local ext = name:sub(-3)
    name = name:sub(1, -5)
    if (t == "file" or t == "link") and (ext == "lua" or ext == "vim") and not M.disabled_rtp_plugins[name] then
      files[#files + 1] = path
    end
  end)
  -- plugin files are sourced alphabetically per directory
  table.sort(files)
  for _, path in ipairs(files) do
    M.source(path)
  end
end
```

そして、関連するコードも追いかけていきますと、`.vim` と `.lua` を区別していないことが分かります。

そのため、`runtime/plugin/dir.lua` が `runtime/plugin/netrwPlugin.vim` より先に読み込まれることになります。

## まとめ

プラグイン同士の衝突を解消する過程でプラグインの読み込み順が Neovim と Lazy.nvim で違うという面白いことを発見しましたので、その調査結果をまとめました。

この記事が誰かの参考になれば幸いです。
