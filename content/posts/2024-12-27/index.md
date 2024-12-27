---
# type: docs 
title: Lazy.nvim でローカルにあるプラグインを読み込む方法
date: 2024-12-27T16:49:10+09:00
featured: false
draft: false
comment: true
toc: true
tags: [neovim]
---

## 前置き

拙作のプラグインである [extend_word_motion.nvim](https://github.com/s-show/extend_word_motion.nvim) を開発するため、ローカルにあるプラグインを [lazy.nvim](https://lazy.folke.io/) で読み込む必要がありましたので、そのための設定を備忘録として残します。

## 環境

```bash
❯ nvim --version
NVIM v0.10.2
Build type: Release
LuaJIT 2.1.1713773202
Run "nvim -V1 -v" for more info
```

```
# lazy.nvim
version 11.16.2
tag     v11.16.2
branch  main
commit  7e6c863
```

```bash
~/.config/nvim
  ├── init.lua
  ├── lazy-lock.json
  ├── lua
  │  ├── config
  │  ├── plugins
  │  │  ├── ...
  │  │  ├── extend_word_motion-nvim.lua
  │  │  └── ...
  │  └── setting
```

## 必要な設定

ローカルプラグインを読み込むための設定は、公式リファレンスの [configuration](https://lazy.folke.io/configuration) と [Examples](https://lazy.folke.io/spec/examples) で以下のとおり提示されています。それぞれの設定の説明は、コメントに書かれています。

> ```lua
> dev = {
>     -- Directory where you store your local plugin projects. If a function is used,
>     -- the plugin directory (e.g. `~/projects/plugin-name`) must be returned.
>     ---@type string | fun(plugin: LazyPlugin): string
>     path = "~/projects",
>     -- （拙訳）
>     -- あなたがローカルプラグインのプロジェクトを保存したディレクトリ。function を使うのであれば、
>     -- プラグインのディレクトリ（例: `~/projects/plugin-name`）が返される必要がある。
>     ---@type string | fun(plugin: LazyPlugin): string
>
>     ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
>     patterns = {}, -- For example {"folke"}
>     -- （拙訳）
>     ---@type string[] これらのパターンにマッチするプラグインは、Github から取得してくる代わりにローカルにあるものを使います。
>
>     fallback = false, -- Fallback to git when local plugin doesn't exist
> },
> ```

> ```lua
> return {
>   -- local plugins need to be explicitly configured with dir
>   { dir = "~/projects/secret.nvim" },
>   （拙訳）
>   -- ローカルプラグインは dir オプションを使って明示的に設定される必要があります。
>
>   -- local plugins can also be configured with the dev option.
>   -- This will use {config.dev.path}/noice.nvim/ instead of fetching it from GitHub
>   -- With the dev option, you can easily switch between the local and installed version of a plugin
>   { "folke/noice.nvim", dev = true },
>   （拙訳）
>   -- ローカルプラグインは、dev オプションを使うことでも設定されます。
>   -- GitHub からフェッチする代わりに {config.dev.path}/noice.nvim/ が使われます。
>   -- dev オプションを使うと、ローカル版とインストール版の間でプラグインのバージョンを簡単に切り替えられます。
> }
> ```

この説明と、ローカルプラグインのファイル構造を踏まえて、`init.lua` と `lua/plugin/extend_word_motion.lua` を以下のとおり設定しました。

```bash
~/my_neovim_plugins
  └── extend_word_motion.nvim
     ├── doc
     │  ├── extend_word_motion.txt
     │  └── tags
     ├── LICENSE
     ├── lua
     │  └── extend_word_motion
     │     ├── init.lua
     │     └── util.lua
     ├── plugin
     │  └── extend_word_motion.vim
     └── README.md
```

```lua
-- init.lua
require("lazy").setup({
  dev = {
    path = "~/my_neovim_plugins",
  },
  spec = {
    import = 'plugins',
  }
})
```

```lua
-- lua/plugins/extend_word_motion.lua
return {
  dir = '~/my_neovim_plugins/extend_word_motion.nvim',
  opts = {},
  dependencies = {
    'sirasagi62/tinysegmenter.nvim'
  },
}
```

この設定により、`~/my_neovim_plugins/extend_word_motion.nvim` で開発しているローカルプラグインを lazy.nvim で読み込むことができました。

## ローカル版と GitHub 版の切り替え

開発が一段落すると GitHub にプッシュすると思いますが、`init.lua` と `lua/plugins/extend_word_motion.lua` を以下のとおり変更すると、GitHub 版とローカル版を簡単に切り替えられるようになります。

```lua
-- init.lua
require("lazy").setup({
  dev = {
    path = "~/my_neovim_plugins",
    patterns = { 'extend_word_motion.nvim' },
  },
  spec = {
    import = 'plugins',
  }
})
```

```lua
-- lua/plugins/extend_word_motion.lua
return  {
  's-show/extend_word_motion.nvim',
  dev = true,
  opts = {},
  dependencies = {
    'sirasagi62/tinysegmenter.nvim'
  },
}
```
`dev` を `true` にすればローカル版が読み込まれ、`false` にすると GitHub 版が読み込まれます。

## 補足

もし、ローカルプラグインを追加する場合、そのプラグインの設定ファイルを `lua/plugins` に作成すればOKです。ここでは `~/my_neovim_plugins/test_plugin` というプラグインを追加しています。

```bash
~/my_neovim_plugins
  ├── extend_word_motion
  │   ├── doc
  │   │  ├── extend_word_motion.txt
  │   │  └── tags
  │   ├── LICENSE
  │   ├── lua
  │   │  └── extend_word_motion
  │   │     ├── init.lua
  │   │     └── util.lua
  │   ├── plugin
  │   │  └── extend_word_motion.vim
  │   └── README.md
  └── test_plugin
      └── plugin
          └── test_plugin.vim
```

```lua
-- lua/plugins/test_plugin.lua
return {
  dir = '~/my_neovim_plugins/test_plugin',
}
```

この設定で `~/my_neovim_plugins/testest_plugin` が読み込まれます。
