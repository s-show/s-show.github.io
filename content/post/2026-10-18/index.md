---
title: "日本語入力を Skkeleton から Skkelua に変えてみました" # Title of the blog post.
date: 2026-10-17T23:42:41+09:00 # Date of post creation.
description: "Article description." # Description used for search engine.
featured: true # Sets if post is a featured post, making appear on the home page side bar.
draft: true # Sets whether to render this page. Draft of true will not be rendered.
toc: true # Controls if a table of contents should be generated for first-level links automatically.
# menu: main
usePageBundles: false # Set to true to group assets like images in the same folder as this post.
tags:
  - neovim
  - skk
# comment: false # Disable comment if false.
---

## Skkelua とは？

Skkelua は Lua で書かれた Neovim 専用の SKK で、[vim-skk/skkeleton](https://github.com/vim-skk/skkeleton) の TypeScript 実装を参考にして開発されたものです。

Skkeleton は [vim-denops/denops.vim](https://github.com/vim-denops/denops.vim) 経由で [Deno](https://deno.com/) をランタイムとして利用することで Vim/Neovim 両方に対応していますが、Skkelua は Lua で書かれていますので、Neovim 専用となっています。

Skkeleton に不満があっての乗り換えではなく、Skkelua が新しい SKK ということで興味があったのと、Skkeleton を

- Skkeleton + ddc.vim + pum.vim
- Skkeleton + blink.cmp + blink-cmp-skkeleton

の組み合わせで使っていると、トラブルシューティングに手間取ることがありましたので、思い切って

- Skkelua + ビルトイン補完機能

でどこまでできるか試してみることにしました。

なお、記事の途中では変更箇所のみ示していますが、最後に設定全体のコードをコメント付きで掲載していますので、そちらだけ見てピックアップすることも可能です。

## Skkelua の設定

### インストール

[lazy.nvim]() を使って最低限の設定を行う場合の設定ファイルは以下のとおりです。

```lua
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      -- SKK の辞書ファイルの場所を指定する 
	  globalDictionaries = { "~/.skk/SKK-JISYO.L" },
    })
    -- ctrl-j で Skkelua のオン/オフを切り替える
    vim.keymap.set({ "i", "c" }, "<C-j>", "<Plug>(skkelua-toggle)")

    -- 設定ファイルを読み込んだ時点で初期化することですぐに使えるようにしている
    require("skkelua").initialize()
  end,
}
```

### 補完機能との連携

#### skkelua の設定

上記の設定ファイルを用意して `:Lazy` コマンドからインストールすれば Skkelua を使えますが、これだけでは ビルトイン補完機能とは連携できません。ビルトイン補完機能と連携するには、以下の設定を追加します。

```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      globalDictionaries = { "~/.skk/SKK-JISYO.L" },
+     completion = {
+       enabled = true,             -- 変換候補を補完メニューに表示する機能をオン
+     },
    })
    ...
  end,
}
```

次に、以下の2つの動作を実現するための設定を追加します。

- 補完候補が表示されたら自動的に最初の候補が選択される
- 補完候補にフォーカスしてもバッファのテキストには反映させない

```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      globalDictionaries = { "~/.skk/SKK-JISYO.L" },
      completion = {
        enabled = true,             -- 変換候補を補完メニューに表示する機能をオン
+       insertOnSelect = false,     -- 候補にフォーカスした時点では本文に挿入しない
+       deferOkuri = false,         -- 送り仮名確定でも自動変換せず、第一候補を自動選択する
      },
    })
    ...
  end,
}
```

#### Neovim 本体の設定

それから、Neovim のビルトイン補完機能を以下のとおり設定します。この設定については、skkelua 以外の補完機能にも関係するため、skkelua の設定とは別のファイルに追加しています。

```lua
-- built in completion
vim.opt.autocomplete = true
vim.opt.autocompletedelay = 200
-- ポップアップメニューに罫線を追加
vim.opt.pumborder = 'rounded'
vim.opt.winborder = 'rounded'
vim.opt.complete = 'd^5,o^10,t^5,f'
vim.opt.completeopt = {
  'menu',      -- 補完メニューを表示する
  'menuone',   -- 候補が1つでも補完メニューを表示する
  'noinsert',  -- 補完候補を決定するまでメニューのアイテムをバッファに挿入しない
  'popup',     -- popupを入れると候補の説明がプレビューされる
}

-- HACK: ドキュメントポップアップに無理やりボーダーを付ける
-- 現状 winborder や completeopt=popup だけではドキュメントfloatのボーダーを制御できない
-- https://github.com/neovim/neovim/issues/38248
-- 将来的に completepopup オプション等が実装されればこのワークアラウンドは不要になる
local orignal_complete_set = vim.api.nvim__complete_set
vim.api.nvim__complete_set = function(...)
  local result = orignal_complete_set(...)
  if result and result.winid then
    pcall(vim.api.nvim_win_set_config, result.winid, { border = 'rounded' })
  end
  return result
end
```

#### LSP の設定

ここまでの設定で Skkelua を有効にして `;hokan` と入力すれば `ほかん` で始まる単語が補完メニューに表示されるようになりましたが、問題が発生しました。

その問題は、`ほかん` と入力して `補完` を選択すると、同じバッファにある `補完` を含んだ文章が続きの補完候補として補完メニューに表示されてしまうという問題です。

```
# イメージ図
入力した文字
 ↓
補完
    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    ┃補完メニューを表示する                                         ┃
    ┃候補が1つでも補完メニューを表示する                            ┃
    ┃補完候補を決定するまでメニューのアイテムをバッファに挿入しない ┃
    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
      ↑
   `補完` 入力後にこんな感じの補完メニューが表示される
```

これはかなり邪魔なので skkelua の設定や Neovim の補完の設定を変更して解消しようとしましたが、上手くいきませんでした。そこで Claude に相談したところ、以下のとおり原因が判明しました。

- Lua の LSP の lua-language-server には、ファイル内の単語を補完候補にする機能（[completion.showWord](https://luals.github.io/wiki/settings/#completionshowword)）がある。
- この機能は、文脈に合った候補があればそれを表示し、文脈に合った候補が無ければ、ファイルの本文から切り出した「名前」を単語候補として返す。
- 単語候補を本文から切り出す際のパターンは `'[%a_\x80-\xff][%w_\x80-\xff]*'` で、`\x80-\xff` は ASCII 以外のバイト全てに該当するので、日本語は文字の種類に関係なく `、` や `。` まで含めて名前の一部とみなされて次の ASCII 文字までの日本語の文章が単語候補として返される1語となる。
- 候補の絞り込みが「先頭一致」ではなく「あいまい一致」なので、先頭が `補完` ではない文章まで補完候補に登場してしまう。
- `completion.showWord` を `Disable` に設定すれば上記の処理は実行されないが、デフォルト値は `Fallback` となっており、この場合、文脈に合った候補が無ければ上記の処理が実行されてしまう。
- また、LSP の設定を `vim.lsp.completion.enable(..., { autotrigger = true })` としていることで lua-language-server の補完候補が自動的に補完メニューに表示されるので、上記の単語候補が補完メニューに表示されてしまう。

この問題に対処するため、Lua の LSP に以下の設定を追加しました。

```diff
return {
  cmd = { 'lua-language-server' },
  settings = {
    Lua = {
      semantic = {
        enable = false,
      },
+     completion = {
+       showWord = 'Disable',
+     },
    },
  },
}

```

なお、`.nix` や `.html` では同様の問題が発生していませんので、現時点では lua-language-server のみ設定しています。


### skkelua の有効・無効の引き継ぎ

「インサートモード→ノーマルモード→インサートモード」と推移した際に、最初のインサートモードの skkelua の有効・無効の状態を2回目のインサートモードで復元したい場合、以下の設定を追加します。

```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      globalDictionaries = {
        ...
      },
      completion = {
        ...
      },
+     keepState = true,             -- Insert モードを抜けても skklua の状態を保存する
    })
    ...
  end,
}
```

### 入力モードの引き継ぎ

インサートモードで編集中に skkelua を「有効→無効→有効」と切り替えた際に、無効化する前の入力モード（かな/カナ/半角カナ/全角英数字）を有効化後に復元したい場合、以下の設定を追加します。

```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      globalDictionaries = {
        ...
      },
      completion = {
        ...
      },
+     keepMode = true,              -- 無効化しても入力モードを保持する
      keepState = true,             -- Insert モードを抜けても skklua の状態を保存する
    })
    ...
  end,
}
```

### かなテーブルを編集

#### `jj` でノーマルモードに戻る

かな入力をオンにしている状態で `jj` をタイプしたらノーマルモードに戻れるようにするには、以下の設定を追加して、かなテーブルに「`jj` に "escape" 機能を割り当てる」という設定を追加します。


```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      ...
    )}
+   require("skkelua").register_kanatable("rom", {
+     ["jj"]  = "escape", -- 機能名を指定
+   })
    ...
  end,
}
```

#### 全角英数字モードで全角スペースを入力する

skkelua の全角英数字モードで全角スペースを入力するには、`z ` と入力する必要があります。

全角スペースはコーディングではトラブルの元なので、意図した場合のみ入力できるようにする、という設計は妥当だと思いますが、全角英数字モードをコーディングで使うことはまず無いので、全角英数字モードでは全角スペースを簡単に入力できるようにしました。

具体的には、かなテーブルを編集して、` (半角スペース)` を `　(全角スペース)` に変換するようにしました。

```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      ...
    })
    require("skkelua").register_kanatable("rom", {
      ["jj"]  = "escape", -- 機能名を指定
    })
+   -- 全角英数字モードのかなテーブルを指定するには "rom" ではなく "zen" を指定する
+   require("skkelua").register_kanatable("zen", {
+     [" "] = { "　", "" },  -- {確定文字列, 残りフィード}
+   })
    ...
  end,
}
```


### SKK のモード（かな、英数など）をインジケーターとして表示する

現在のモードをカーソル横にインジケーターとして表示するには、以下の設定を追加します。

```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      ...
+     indicator = {
+       alwaysShown = false,        -- skkelua 有効時のみ表示
+       fadeOutMs = 1000,           -- インジケーターの表示時間を1秒に設定
+       border = "rounded",         -- nvim_open_win の border
+                                   -- (nil なら枠なし。'winborder' は適用しない)
+     },
    })
    ...
  end,
}
```

ここでは、skkelua を有効化した場合のみ `ひら`、`カタ` などのインジケーターを表示するようにし、skkelua 無効時はインジケーターを表示しないようにしています。もし、skkelua を無効化したときにもインジケーターを表示したい場合、`alwaysShown` を `true` にすれば OK です。 

#### nvim-lualine/lualine.nvim と組み合わせてステータスラインにも表示する

skkelua では autocmd を使ってイベントドリブンな設定ができるので、nvim-lualine/lualine.nvim の設定を動的に変更して skkelua のモードを表示できるようにします。

ここでは、インサートモードとノーマルモードで skkelua のモードを次のとおり表示するようにします。

- インサートモード
    - `ひらがな`
    - `カタカナ`
    - `半角ｶﾅ`
    - `全角英数字`
    - `SKK off`
- ノーマルモード
    - `SKK off(ひら)`
    - `SKK off(カタ)`
    - `SKK off(半角)`
    - `SKK off(全角)`
    - `(SKK off)`

```diff
{
  "https://github.com/s-show/skkelua.nvim",
  config = function()
    require("skkelua").config({
    })

+   -- SKK のモードを lnvim-lualine/lualine.nvim に表示する
+   -- https://github.com/nvim-lualine/lualine.nvim/discussions/1017 を参考に実装した
+   -- skkelua 無効化（`l` キーのオフ含む）の前に直前の skkelua の状態をグローバル変数に格納
+   -- このイベントは `skkelua-mode-changed` の前に発生する
+   vim.api.nvim_create_autocmd('User', {
+     pattern = { 'skkelua-disable-pre' },
+     callback = function()
+       local mode = require('skkelua').mode()
+       if mode == 'hira' then
+         vim.g.skk_mode = 'SKK off(ひら)'
+       elseif mode == 'kata' then
+         vim.g.skk_mode = 'SKK off(カタ)'
+       elseif mode == 'hankata' then
+         vim.g.skk_mode = 'SKK off(半角)'
+       elseif mode == 'zenkaku' then
+         vim.g.skk_mode = 'SKK off(全角)'
+       else
+         vim.g.skk_mode = '(SKK off)'
+       end
+     end
+   })
+   -- イベントは skkelua のモード切り替えの度に発生する
+   -- このイベントは `skkelua-disable-pre` の後に発生する
+   vim.api.nvim_create_autocmd('User', {
+     pattern = { 'skkelua-mode-changed' },
+     callback = function()
+       local lualine_require = require("lualine_require")
+       local modules = lualine_require.lazy_require({ config_module = "lualine.config" })

+       local current_config = modules.config_module.get_config()

+       local function get_skk_mode()
+         local mode = require('skkelua').mode()
+         if mode == 'hira' then
+           return [[ひらがな]]
+         elseif mode == 'kata' then
+           return [[カタカナ]]
+         elseif mode == 'hankata' then
+           return [[半角ｶﾅ]]
+         elseif mode == 'zenkaku' then
+           return [[全角英数字]]
+         else
+           return [[SKK off]]
+         end
+       end

+       current_config.sections.lualine_x = { get_skk_mode, 'encoding', { 'fileformat', icons_enabled = true, symbols = { unix = 'LF', dow = 'CRLF', mac = 'CR' } },
+         'filetype' }
+       require("lualine").setup(current_config)
+     end
+   })
+   -- このイベントは `skkelua-mode-changed` の後に発生する
+   -- このイベントの前に `status.mode = ""` が実行されて skkelua が強制的にオフになる。
+   vim.api.nvim_create_autocmd('User', {
+     pattern = { 'skkelua-disable-post' },
+     callback = function()
+       local lualine_require = require("lualine_require")
+       local modules = lualine_require.lazy_require({ config_module = "lualine.config" })

+       local current_config = modules.config_module.get_config()
+       local function get_skk_mode()
+         return vim.g.skk_mode
+       end

+       current_config.sections.lualine_x = { get_skk_mode, 'encoding', { 'fileformat', icons_enabled = true, symbols = { unix = 'LF', dow = 'CRLF', mac = 'CR' } },
+         'filetype' }
+       require("lualine").setup(current_config)
+     end
+   })
    ...
  end,
}


```

設定後の表示は次のとおりです。

インサートモードでの表示

{{< bsimage src="./images/insert_mode.png" title="" >}}

ノーマルモードでの表示

{{< bsimage src="./images/normal_mode.png" title="" >}}

### その他の設定

#### 雑多な設定

その他の雑多な設定は次のとおりです。設定内容はコメントに記載していますが、一点補足しますと、`<C-j>` による skkelua の有効/無効のトグル機能について、skkelua が無効なら有効化、skkelua が「有効＆カナ入力」なら「有効にしたままかな入力」という動作に切り替えています。

```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      ...
+     eggLikeNewline = true,        -- 変換中の `<CR>` で確定のみ行う
+     pureSpace = false,            -- Space を変換に使う
+     setUndoPoint = true,          -- 変換 1 回を独立した undo 単位にする
+     registerConvertResult = true, -- カタカナ変換等の結果をユーザー辞書に登録する
      ...
    })

+   -- Ctrl-j で skkelua を有効化 & カナ入力をかな入力に切り替え
+   vim.keymap.set({ "i", "c" }, "<C-j>", function()
+     local mode = require('skkelua').mode()
+     if mode == '' then
+       require("skkelua").handle("enable")
+     elseif mode == 'kata' then
+       require("skkelua").handle("handleKey", { ["function"] = "hirakana" })
+     end
+   end, { expr = true })
+   -- ctrl-e でキャンセルする
+   vim.keymap.set("i", "<C-e>", function()
+     local phase = require("skkelua").phase()
+     if vim.tbl_contains(
+           { "input:okurinasi", "input:okuriari", "henkan" }, phase)
+     then
+       require("skkelua").handle("handleKey", { ["function"] = "escape" })
+       return ""
+     end
+     return "<C-e>"
+   end, { expr = true })
    ...
  end,
}
```

#### Fork 版専用の設定

skkeleton や Windows の SKK の CorvusSKK で Abbrev モードにして `/neovim` と入力して確定した場合、`neovim` という文字列がバッファやテキストエリアに入力されますが、skkelua では ` neovim` という形でアルファベットの前に半角スペースが追加されます。

私は Abbrev モードを「SKK を有効にしたまま半角英数字を入力できるモード」として使用していますが、この仕様があるとアルファベットの手前に半角スペースが入ることを前提に入力しなければならなくなり、考えることが増えてしまいます。

そこで、Fork して `completion.abbrevWithSpace` というオプションを追加しました。オプションのデフォルト値は `true` で、この状態なら従来どおりアルファベットの手前に半角スペースが追加され、`false` にすると半角スペースが追加されなくなります。

設定と Fork 版の URL は以下のとおりです。

```diff
{
  "kjuq/skkelua.nvim",
  config = function()
    require("skkelua").config({
      globalDictionaries = { "~/.skk/SKK-JISYO.L" },
      completion = {
        enabled = true,             -- 変換候補を補完メニューに表示する機能をオン
        insertOnSelect = false,     -- 候補にフォーカスした時点では本文に挿入しない
        deferOkuri = false,         -- 送り仮名確定でも自動変換せず、第一候補を自動選択する
+       abbrevWithSpace = false     -- abbrev 入力でアルファベットの前に半角スペースを追加しない
      },
    })
    ...
  end,
}
```

Fork版 → [s-show/skkelua.nvim: Yet another SKK implemention for Neovim in pure Lua](https://github.com/s-show/skkelua.nvim)

## 最終的な設定コード

これまでの設定を全てまとめたコードを掲載します。

```lua
  {
    "https://github.com/s-show/skkelua.nvim",
    config = function()
      require("skkelua").config({
        mappedKeys = mapped_keys,
        globalDictionaries = {
          vim.fn["expand"]('~/.config/nvim/skk_dict/SKK-JISYO.L'),
          vim.fn["expand"]('~/.config/nvim/skk_dict/SKK-JISYO.geo'),
          vim.fn["expand"]('~/.config/nvim/skk_dict/SKK-JISYO.jinmei'),
          vim.fn["expand"]('~/.config/nvim/skk_dict/SKK-JISYO.law'),
        },
        completion = {
          enabled = true,             -- 変換候補を補完メニューに表示する機能をオン
          insertOnSelect = false,     -- 候補にフォーカスした時点では本文に挿入しない
          deferOkuri = false,         -- 送り仮名確定でも自動変換せず、第一候補を自動選択する
          abbrevWithSpace = false     -- abbrev 入力でアルファベットの前に半角スペースを追加しない
        },
        keepMode = true,              -- 無効化しても入力モードを保持する
        keepState = true,             -- Insert モードを抜けても skklua の状態を保存する
        eggLikeNewline = true,        -- 変換中の `<CR>` で確定のみ行う
        pureSpace = false,            -- Space を変換に使う
        setUndoPoint = true,          -- 変換 1 回を独立した undo 単位にする
        registerConvertResult = true, -- カタカナ変換等の結果をユーザー辞書に登録する
        indicator = {
          alwaysShown = false,        -- false なら skkelua 有効時のみ表示
          fadeOutMs = 1000,           -- インジケーターの表示時間を1秒に設定
          border = "rounded",         -- nvim_open_win の border
          -- (nil なら枠なし。'winborder' は適用しない)
        },
      })

      -- Ctrl-j で skkelua を有効化 & カナ入力をかな入力に切り替え
      vim.keymap.set({ "i", "c" }, "<C-j>", function()
        local mode = require('skkelua').mode()
        if mode == '' then
          require("skkelua").handle("enable")
        elseif mode == 'kata' then
          require("skkelua").handle("handleKey", { ["function"] = "hirakana" })
        end
      end, { expr = true })

      -- ctrl-e でキャンセルする
      vim.keymap.set("i", "<C-e>", function()
        local phase = require("skkelua").phase()
        if vim.tbl_contains(
              { "input:okurinasi", "input:okuriari", "henkan" }, phase)
        then
          require("skkelua").handle("handleKey", { ["function"] = "escape" })
          return ""
        end
        return "<C-e>"
      end, { expr = true })

      -- 「かな変換テーブル」に `jj` を `escape` に変換するルールを追加
      require("skkelua").register_kanatable("rom", {
        ["jj"]  = "escape", -- 機能名を指定
      })
      -- 全角英数字モードのかなテーブルを指定するには "rom" ではなく "zen" を指定する
      require("skkelua").register_kanatable("zen", {
        [" "] = { "　", "" },
      })

      -- SKK のモードを lnvim-lualine/lualine.nvim に表示する
      -- https://github.com/nvim-lualine/lualine.nvim/discussions/1017 を参考に実装した
      -- skkelua 無効化（`l` キーのオフ含む）の前に直前の skkelua の状態をグローバル変数に格納
      -- このイベントは `skkelua-mode-changed` の前に発生する
      vim.api.nvim_create_autocmd('User', {
        pattern = { 'skkelua-disable-pre' },
        callback = function()
          local mode = require('skkelua').mode()
          if mode == 'hira' then
            vim.g.skk_mode = 'SKK off(ひら)'
          elseif mode == 'kata' then
            vim.g.skk_mode = 'SKK off(カタ)'
          elseif mode == 'hankata' then
            vim.g.skk_mode = 'SKK off(半角)'
          elseif mode == 'zenkaku' then
            vim.g.skk_mode = 'SKK off(全角)'
          else
            vim.g.skk_mode = '(SKK off)'
          end
        end
      })
      -- イベントは skkelua のモード切り替えの度に発生する
      -- このイベントは `skkelua-disable-pre` の後に発生する
      vim.api.nvim_create_autocmd('User', {
        pattern = { 'skkelua-mode-changed' },
        callback = function()
          local lualine_require = require("lualine_require")
          local modules = lualine_require.lazy_require({ config_module = "lualine.config" })

          local current_config = modules.config_module.get_config()

          local function get_skk_mode()
            local mode = require('skkelua').mode()
            if mode == 'hira' then
              return [[ひらがな]]
            elseif mode == 'kata' then
              return [[カタカナ]]
            elseif mode == 'hankata' then
              return [[半角ｶﾅ]]
            elseif mode == 'zenkaku' then
              return [[全角英数字]]
            else
              return [[SKK off]]
            end
          end

          current_config.sections.lualine_x = { get_skk_mode, 'encoding', { 'fileformat', icons_enabled = true, symbols = { unix = 'LF', dow = 'CRLF', mac = 'CR' } },
            'filetype' }
          require("lualine").setup(current_config)
        end
      })
      -- このイベントは `skkelua-mode-changed` の後に発生する
      -- このイベントの前に `status.mode = ""` が実行されて skkelua が強制的にオフになる。
      vim.api.nvim_create_autocmd('User', {
        pattern = { 'skkelua-disable-post' },
        callback = function()
          local lualine_require = require("lualine_require")
          local modules = lualine_require.lazy_require({ config_module = "lualine.config" })

          local current_config = modules.config_module.get_config()
          local function get_skk_mode()
            return vim.g.skk_mode
          end

          current_config.sections.lualine_x = { get_skk_mode, 'encoding', { 'fileformat', icons_enabled = true, symbols = { unix = 'LF', dow = 'CRLF', mac = 'CR' } },
            'filetype' }
          require("lualine").setup(current_config)
        end
      })

      -- 設定ファイルを読み込んだ時点で初期化することですぐに使えるようにしている
      require("skkelua").initialize()
    end,
  }
```

## 参考情報

- [kjuq/skkelua.nvim: Yet another SKK implemention for Neovim in pure Lua](https://github.com/kjuq/skkelua.nvim)
- [neovim 0.12からはネイティブの補完で十分そう - Panda Noir](https://www.pandanoir.info/entry/2026/04/19/095000)
- [Lua Language Server | Wiki](https://luals.github.io/wiki/)
- [Dynamically add sections? · nvim-lualine/lualine.nvim · Discussion #1017](https://github.com/nvim-lualine/lualine.nvim/discussions/1017)

