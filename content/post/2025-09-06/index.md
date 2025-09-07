---
title: Neovim で Treesitter を使って Markdown コードブロックを自動実行する方法
date: 2025-09-06T18:09:47+09:00 # Date of post creation.
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

## はじめに

先日、私が開発している Neovim のプラグインの [ft-mapper.nvim](https://github.com/s-show/ft-mapper.nvim/) を V2 にバージョンアップしましたが、このバージョンアップは、当初は Lua を Vimscript に置き換えようとしていました。理由は、マルチバイト文字の取扱いは Vimscript の方が向いているだろうと思ったためです。

とはいえ、いきなり本番用のコードを置き換えるのは無謀なので「小さなコードを書く→コードを実行する→コードを修正する」のサイクルを素早く回してコードを置き換えようとしました。そのためには、コードを書いたら即実行できる環境が必要ですが、Vimscript には Codepen.io  のようなオンラインで即座にコードを試せる環境がありません。そこで、色々考えた結果、Markdown のコードフェンスにコードを書いてその場で実行できれば、サイクルを素早く回せる上、コードとメモを一元的に管理できると気付きました。

そこで、Slack の Vim-jp の [チャットルーム](https://vim-jp.org/docs/chat.html) で相談したところ、**コードを選択して `:'<,'>source` コマンドを実行すればその場でコードを実行できる**と教えてもらいました。

これで「即座にコードを試す」ことはできるようになりましたが、これができると、次は「コードフェンスにカーソルがあるときに任意のキーをタイプしたらコードを実行してくれる」機能が欲しくなりました。

この機能は ChatGPT にコードを書いてもらって実現できましたが、「AI に書いてもらいました」で済ませると自分のレベルアップは実現できませんので、AI に書いたコードを頑張って読み解いてみました。そこで、その解読結果を備忘録としてまとめます。

なお、最初にこの機能の処理の流れをまとめると、次のとおりとなります。

- Treesitter を使ってカーソルがあるコードフェンスの開始行と終了行を取得する
- コードフェンスの中にあるコードを取得してテンポラリファイルに書き込む
- `vim.cmd.source()` or `vim.cmd.luafile()` の引数にテンポラリファイルを指定して実行する

## 実際のコード

実際のコードは以下のとおりです。

```lua
-------------------------------------
-- Markdownパーサを強制使用して取得
-------------------------------------
local function get_md_node_at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown", {})
  if not ok or not parser then return nil end
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local tree = parser:parse()[1]
  if not tree then return nil end
  local root = tree:root()
  return root and root:named_descendant_for_range(row, col, row, col) or nil
end


local function find_child(node, wanted_types)
  if not node then return nil end
  for child in node:iter_children() do
    if wanted_types[child:type()] then
      return child
    end
  end
  return nil
end

local function find_fence_content_via_markdown(bufnr)
  local n = get_md_node_at_cursor(bufnr)
  while n do
    if n:type() == "fenced_code_block" then
      local content = find_child(n, { code_fence_content = true })
      -- info_string も返す
      local info_node = find_child(n, { info_string = true })
      local info = nil
      if info_node then
        info = vim.treesitter.get_node_text(info_node, bufnr)
      end
      return content or n, info
    end
    n = n:parent()
  end
  return nil, nil
end

-------------------------------------
-- 言語名の抽出と判定
-------------------------------------
local function parse_lang_from_info(info)
  if not info or info == "" then return nil end
  local lang = info:match("^%s*([%w_+%.%-]+)")
  if not lang or lang == "" then return nil end
  -- よくある表記ゆれを吸収
  local map = {
    viml = "vim",
    vimscript = "vim",
    vim = "vim",
    lua = "lua",
    luau = "lua",
  }
  return (map[lang] or lang):lower()
end

-------------------------------------
-- フェンス中身を文字列として取得（```除外）
-------------------------------------
local function get_fence_text(bufnr, node)
  local sr, sc, er, ec = node:range() -- endはexclusive

  -- exclusive→inclusive調整
  if ec == 0 then
    er = er - 1
    if er < sr then return {} end
    local last = vim.api.nvim_buf_get_lines(bufnr, er, er + 1, true)[1] or ""
    ec = #last
  else
    ec = ec - 1
  end
  -- 「終端行が閉じフェンス」なら1行手前に寄せる
  local last_line = vim.api.nvim_buf_get_lines(bufnr, er, er + 1, true)[1] or ""
  if last_line:match("^%s*`%s*`%s*`") then
    er = er - 1
    if er < sr then return {} end
    local prev = vim.api.nvim_buf_get_lines(bufnr, er, er + 1, true)[1] or ""
    ec = #prev
  end
  return vim.api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})
end

-------------------------------------
-- 実行器: Vim / Lua / Sh
-------------------------------------
local function exec_vim(lines)
  local tmp = vim.fn.tempname() .. ".vim"
  vim.fn.writefile(lines, tmp)
  vim.cmd.source(tmp)
  vim.notify("Sourced (Vim): " .. tmp, vim.log.levels.INFO)
end


local function exec_lua(lines)
  local tmp = vim.fn.tempname() .. ".lua"
  vim.fn.writefile(lines, tmp)
  vim.cmd.luafile(tmp)
  vim.notify("Sourced (Lua): " .. tmp, vim.log.levels.INFO)
end

-------------------------------------
-- メイン: 言語自動判定で実行
-------------------------------------
local function exec_fence_auto()
  local bufnr = vim.api.nvim_get_current_buf()

  local content_node, info = find_fence_content_via_markdown(bufnr)
  if not content_node the
    vim.notify("Not inside a fenced code block", vim.log.levels.WARN)
    return
  end
  local lines = get_fence_text(bufnr, content_node)
  if #lines == 0 then
    vim.notify("Empty fence content", vim.log.levels.WARN)
    return
  end

  local lang = parse_lang_from_info(info)
  -- 既定: info_string が無い/不明 → Vim とみなす（必要なら "markdown" にも対応可）
  if not lang then lang = "vim" end
  if lang == "vim" then
    exec_vim(lines)
  elseif lang == "lua" then
    exec_lua(lines)
  else
    -- 未対応言語: とりあえず Vim として実行するか、エラーにする
    vim.notify(("Unsupported fence language: %s"):format(lang), vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    vim.api.nvim_buf_create_user_command(args.buf, "FenceExec", exec_fence_auto, {})
    vim.keymap.set("n", "<leader>qr", exec_fence_auto,
      { buffer = args.buf, desc = "Run fenced code content (force markdown parser)" })
  end,
})
```


## コードの解説

ここからコードを再掲しながら内容を解説していきます。なお、エラー処理のコードは再掲・解説ともに省略します。


### 1. この機能のエントリーポイント

この機能のエントリーポイントは、`vim.api.nvim_create_autocmd()` のコールバック関数で呼び出している `vim.keymap.set()` の `rhs` に指定している `exec_fence_auto` 関数です。

`exec_fence_auto` 関数は、最初に現在のバッファ番号を取得し、そのバッファ番号を `find_fence_content_via_markdown()` に渡します。

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    vim.api.nvim_buf_create_user_command(args.buf, "FenceExec", exec_fence_auto, {})
    vim.keymap.set("n", "<leader>qr", exec_fence_auto,
      { buffer = args.buf, desc = "Run fenced code content (force markdown parser)" })
  end,
})

local function exec_fence_auto()
  local bufnr = vim.api.nvim_get_current_buf()
  local content_node, info = find_fence_content_via_markdown(bufnr)
  ...
end
```

### 2. カーソル位置のノード取得

`find_fence_content_via_markdown` 関数は、まず `get_md_node_at_cursor()` にバッファ番号を渡して返り値を `n` 変数に格納します。

`get_md_node_at_cursor` 関数は `vim.treesitter.get_parser()` にバッファ番号とパーサーの種類を示す文字列（`"markdown"`）を渡して、`parser` 変数に構文解析器である `LanguageTree` 型のオブジェクトを格納します。

```lua
local function find_fence_content_via_markdown(bufnr)
  local n = get_md_node_at_cursor(bufnr)
  ...
end

local function get_md_node_at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown", {})
  ...
end
```

`pcall` を使っているのは、パーサーの取得失敗に備えているためです。

### 3. Treesitterによる構文解析

次に `vim.api.nvim_win_get_cursor(0)` 関数でカーソル位置を取得し、行番号と列番号を `row` 変数と `col` 変数に格納します。なお、Neovimの行番号は1ベースですが、Treesitterは0ベースなので `-1` して調整しています。

```lua
local function get_md_node_at_cursor(bufnr)
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
end
```

それから、`parser:parse()[1]` を実行してカレントバッファのテキストの構文木オブジェクトの配列（`TSTree[]`）を取得すると同時に、末尾に `[1]` を付けることで構文木の最初の要素を取得して `tree` 変数（`TSTree`）に格納しています。

```lua
local function get_md_node_at_cursor(bufnr)
  local tree = parser:parse()[1]
end
```

そして、`tree:root()` を実行して構文木オブジェクトから最上位のノード（`TSNode`）を取得して `root` 変数に格納しています。

```lua
local function get_md_node_at_cursor(bufnr)
  local root = tree:root()
end
```

Treesitter の型階層は以下のようになっています：

```
LanguageTree (パーサーオブジェクト)
    ↓ :parse() メソッド
TSTree[] (構文木オブジェクトの配列)
    ↓ [1] で最初の要素取得
TSTree (単一の構文木オブジェクト)
    ↓ :root() メソッド
TSNode (ルートノード)
```

### 4. カーソル位置の正確な特定

`root:named_descendant_for_range()` の引数にカーソル位置を渡して、カーソル位置の名前付きノードを取得して `get_md_node_at_cursor()` 関数の返り値にします。

```lua
return root and root:named_descendant_for_range(row, col, row, col) or nil
```

### 5. フェンスドコードブロックの探索

`find_fence_content_via_markdown()`関数は、取得したノードから親ノードを辿り、`fenced_code_block`タイプのノードを探します。

```lua
local function find_fence_content_via_markdown(bufnr)
  while n do
    if n:type() == "fenced_code_block" then
    end
    n = n:parent()
  end
  return nil, nil
end
```

### 6. コンテンツと言語情報の取得

`fenced_code_block` ノードが見つかったら、そのノードの子ノードの中から特定のノード（`code_fence_content` & `info_string`）を探すため、`find_child()` 関数にノードと探索すべきノードのタイプを渡します。

`find_child()` 関数は、`node:iter_children()` 関数を使って渡されたノードの子ノードを全て取得し、それを `for` 文で順番に処理し、指定されたノードが見つかれば返り値とします。

```lua
local function find_child(node, wanted_types)
  for child in node:iter_children() do
    if wanted_types[child:type()] then
      return child
    end
  end
  return nil
end
```

`find_child()` 関数から指定したノードが返されたら、それらを `content` 変数と `info_node` 変数に格納します。そして、`vim.treesitter.get_node_text()` 関数に `info_node` 変数とバッファ番号を渡して言語名（`` ` ``の後ろの文字列）を取得して `info` 変数に格納しています。

```lua
local function find_fence_content_via_markdown(bufnr)
  while n do
    if n:type() == "fenced_code_block" then
      local content = find_child(n, { code_fence_content = true })
      local info_node = find_child(n, { info_string = true })
      local info = nil
      if info_node then
        info = vim.treesitter.get_node_text(info_node, bufnr)
      end
      return content or n, info
    end
    n = n:parent()
  end
  return nil, nil
end
```

### 7. コード範囲の正確な取得

これで `exec_fence_auto()` に処理が戻り、コードフェンス内のコードを含むノードが `content_node` 変数に格納され、言語名が `info` 変数に格納されます。

次に、`get_fence_text()` 関数にバッファ番号と `content_node` 変数を渡します。`get_fence_text()` 関数は、まず `node:range()` 関数を実行してコードフェンスの範囲を取得して変数に格納します。

```lua
local function exec_fence_auto()
  local content_node, info = find_fence_content_via_markdown(bufnr)
  local lines = get_fence_text(bufnr, content_node)
  if #lines == 0 then
    vim.notify("Empty fence content", vim.log.levels.WARN)
    return
  end
end

local function get_fence_text(bufnr, node)
  -- sr -> 開始行の位置
  -- sc -> 開始行の列の位置
  -- er -> 終了行の位置
  -- ec -> 終了行の列の位置
  local sr, sc, er, ec = node:range() -- endはexclusive
```

それから、Treesitterの 範囲指定が exclusive であることを考慮した調整（`er = er - 1`）や終端行が閉じフェンス（`` ` ``）の場合に除外する処理も行ってから、`return vim.api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})` でコードフェンスのコードを取得して返り値にします。

```lua
local function get_fence_text(bufnr, node)
  -- exclusive→inclusive調整
  if ec == 0 then
    er = er - 1
    if er < sr then return {} end
    local last = vim.api.nvim_buf_get_lines(bufnr, er, er + 1, true)[1] or ""
    ec = #last
  else
    ec = ec - 1
  end
  -- 「終端行が閉じフェンス」なら1行手前に寄せる
  local last_line = vim.api.nvim_buf_get_lines(bufnr, er, er + 1, true)[1] or ""
  if last_line:match("^%s*`%s*`%s*`") then
    er = er - 1
    if er < sr then return {} end
    local prev = vim.api.nvim_buf_get_lines(bufnr, er, er + 1, true)[1] or ""
    ec = #prev
  end
  return vim.api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})
end
```

### 8. 言語の自動判定と正規化

再び `exec_fence_auto()` に処理が戻り、コードフェンス内のコードが `lines` 変数に格納されます。

それから、コードフェンスの言語を判定するため、`parse_lang_from_info()` 関数に `info` 変数を渡します。

`parse_lang_from_info()` 関数は `info:match("^%s*([%w_+%.%-]+)")` で言語名を表わすテキストを抽出して `lang` 変数に格納し、それを `map` テーブルで定義している表記ゆれのリストを使って正しい表記に修正し、それを返り値にします。

```lua
local function exec_fence_auto()
  local lines = get_fence_text(bufnr, content_node)
  local lang = parse_lang_from_info(info)
end

local function parse_lang_from_info(info)
  local lang = info:match("^%s*([%w_+%.%-]+)")
  local map = {
    viml = "vim",
    vimscript = "vim",
    vim = "vim",
    lua = "lua",
    luau = "lua",
  }
  return (map[lang] or lang):lower()
end
```

### 9. コードの実行

これで `exec_fence_auto()` 関数の `lang` 変数に言語の種類が格納されましたので、言語に応じて適切な実行関数を呼び出します。

```lua
local function exec_fence_auto()
  local lang = parse_lang_from_info(info)
  if lang == "vim" then
    exec_vim(lines)
  elseif lang == "lua" then
    exec_lua(lines)
  end
end
```

### 10. 実行処理の詳細

実際の実行は、テンポラリファイルを経由して行われます。`vim.fn.tempname() .. ".vim"` または `vim.fn.tempname() .. ".lua"` でテンポラリファイルのファイル名を設定し、そのテンポラリファイルに `vim.fn.writefile(lines, tmp)` でコードを書き込み、`vim.fn.source()` または `vim.fn.luafile()` の引数に渡してコードを実行します。

```lua
local function exec_vim(lines)
  local tmp = vim.fn.tempname() .. ".vim"
  vim.fn.writefile(lines, tmp)
  vim.cmd.source(tmp)
  vim.notify("Sourced (Vim): " .. tmp, vim.log.levels.INFO)
end

local function exec_lua(lines)
  local tmp = vim.fn.tempname() .. ".lua"
  vim.fn.writefile(lines, tmp)
  vim.cmd.luafile(tmp)
  vim.notify("Sourced (Lua): " .. tmp, vim.log.levels.INFO)
end
```

### 11. Markdownファイル専用の設定

最後に、この機能をMarkdownファイルでのみ有効化します。

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    vim.api.nvim_buf_create_user_command(args.buf, "FenceExec", exec_fence_auto, {})
    vim.keymap.set("n", "<leader>qr", exec_fence_auto,
      { buffer = args.buf, desc = "Run fenced code content (force markdown parser)" })
  end,
})
```

## まとめ

Neovim の Treesitter API を活用することで Markdown のコードフェンスのコードをその場で実行できるようになりました。この記事が何かの参考になれば幸いです。
