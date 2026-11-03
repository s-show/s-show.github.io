---
title: "Neovim の dir プラグインをカスタマイズした" # Title of the blog post.
date: 2026-11-03T23:26:54+09:00 # Date of post creation.
featured: true # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: true # Controls if a table of contents should be generated for first-level links automatically.
# menu: main
tags:
  - neovim
comment: true # Disable comment if false.
archives: 2026/11
---

この記事は[Vim駅伝](https://vim-jp.org/ekiden/)の 2026-11-04 の記事です。
Vim駅伝は常に参加者を募集しています。詳しくは[こちらのページ](https://vim-jp.org/ekiden/about/)をご覧ください。

## 前置き

Neovim のファイラーには [FylerOrg/fyler.nvim: A neovim file manager which can edit file system like a buffer with tree view](https://github.com/FylerOrg/fyler.nvim) を使ってきましたが、[Do we still need a File Explorer Plugin in Neovim 0.13? : r/neovim](https://www.reddit.com/r/neovim/comments/1wxmb3u/do_we_still_need_a_file_explorer_plugin_in_neovim/) で Neovim の v0.13 から組み込みのディレクトリビューワーが導入されたことを知りましたので、導入してみることにしました。

導入したら Fyler.nvim を削除しても問題無さそうなところまでカスタマイズできましたので、カスタマイズの内容などを備忘録としてメモします。

実際のコードは末尾に掲載していますので、ここでは実装の際にひっかかった問題などを紹介します。

## dir プラグインの機能

dir プラグインは、Netrw から「ローカルのディレクトリを一覧する」機能を取り出して Lua で書き直したもので、デフォルトでは以下の機能を備えています。

- `:edit .` を実行すると選択中のウィンドウでカレントディレクトリのディレクトリとファイルを一覧表示する
- `-` で1つ上のディレクトリに移動する
- `<CR>` でディレクトリ/ファイルを開く。開いたら dir は閉じられる。
- `<C-r>` で一覧を更新する

このように非常にシンプルなプラグインですが、上記の Reddit の投稿者は

- ディレクトリ/ファイル削除
- ディレクトリ/ファイル作成
- ディレクトリ/ファイルリネーム
- ディレクトリ/ファイルの切り取り/コピー/ペースト

機能を追加してファイラーとして使えるようにしています。

私もこれを見て dir プラグインをカスタマイズしたのですが、同じことをしても面白くないので、Fyler.nvim で実現した

- フローティングウィンドウで開く
- 選択したファイルを垂直/水平分割で開く

機能を追加した上で、`?` でキーマッピングを確認できるようにもしました。

## 実際の動作の様子

{{< video src="images/dir_plugin_demo_video.mp4" type="video/mp4" preload="metadata" >}}

## カスタマイズの際にひっかかった問題

### Netrw との競合

前回の記事で紹介しました「Neovim と Lazy.nvim でのプラグイン読み込み順の違い」により、Netrw と dir の間で衝突が発生しました。Lazy.nvim を使う限り読み込み順は変えられないので、

```lua
-- netrw 無効化
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1
```

を設定に追加して、Netrw 自体を無効化しました。

### キーマッピング割り当て

Fyler.nvim は `-` キーだけで開くようにしていましたので、以下のとおりキーマッピングして `-` だけで dir が開くようにしました。なお、`float_win.Create_floating_Window()` は自作の関数で、コードは末尾に載せています。

```lua
local map = vim.keymap
map.set('n', '-', function()
  local win_id, _ = float_win.Create_floating_Window({ footer = "'?' open keymap in cmdline." })
  if win_id ~= false then
    vim.cmd("edit ./")
  end
end)
```

しかし、この設定により `-` で dir が開くようになったものの、dir を開いている状態で `-` をタイプしても1つ上のディレクトリに移動せず、代わりにカレントディレクトリが開かれるようになりました。

原因は、dir は初期化の際に `-` に「1つ上のディレクトリに移動する」機能をマッピングしますが、初期化の時点で `-` に何らかの機能がマッピングされていると `-` へのマッピングがスキップされるようになっていて、かつ、上記の設定が dir の初期化より先に実施されるためでした。なお、dir の初期化の際のマッピングのコードは以下のとおりです。

```lua
-- $VIMRUNTIME/plugin/dir.lua:34
if vim.fn.mapcheck('-', 'n') == '' and vim.fn.hasmapto('<Plug>(nvim-dir-up)', 'n') == 0 then
  vim.keymap.set('n', '-', '<Plug>(nvim-dir-up)', { silent = true, desc = 'Open parent directory' })
end
```

この問題については、以下のとおりバッファローカルなキーマッピングを実行することで対処しました。`nvim_create_autocmd()` の `pattern` に指定している `DirReadPost` は、dir プラグインのカスタマイズのために用意されているもので、ファイルなどのリストがレンダリングされた後に発火するイベントです。ヘルプではリストの並べ替えなどを実施するために利用する方法が紹介されていますが、ここではバッファローカルなキーマッピングを実行するために利用しています。

```lua
local api = vim.api
local map = vim.keymap

local KEYMAPS = {
  {
    lhs = '-', desc = '親ディレクトリへ（{count}- もOK）',
    remap = true, silent = true,
    rhs = function()
      return '<Plug>(nvim-dir-up)'
    end,
  },
}

local function setup_keymaps(bufnr)
  for _, k in ipairs(KEYMAPS) do
    map.set('n', k.lhs, k.rhs(bufnr), {
      buf = bufnr,
      desc = 'dir: ' .. k.desc,
      remap = k.remap == true,
      silent = k.silent == true,
    })
  end
end

api.nvim_create_autocmd('User', {
  pattern = 'DirReadPost',
  group = augroup,
  callback = function(args)
    vim.schedule(function()
      setup_keymaps(args.buf)
    end)
  end,
})
```

## 実際のコード

実際のコードは以下のとおりです。参考にした Reddit の投稿者はファイル操作をシェルコマンドで実行していましたが、こちらでは Neovim の関数などを使って実行しています。

```lua
local float_win = require('util.floating_window')
local dir = require('nvim.dir')

local api = vim.api
local map = vim.keymap
local fn = vim.fn

local LEVEL = vim.log.levels

local function warn(msg)
  vim.notify('dir: ' .. msg, LEVEL.WARN)
end

local function fail(msg)
  vim.notify('dir: ' .. msg, LEVEL.ERROR)
end

-- nvim.dir._reload / _open_entry はアンダースコア付き = 非公開API.
-- Neovim 側の改名で消えたとき, 各操作が静かに落ちるより起動時1回の警告の方が被害が小さい.
vim.schedule(function()
  local missing = {}
  for _, name in ipairs({ '_reload', '_open_entry' }) do
    if type(dir[name]) ~= 'function' then
      missing[#missing + 1] = 'nvim.dir.' .. name
    end
  end
  if #missing > 0 then
    warn('非公開APIが見つかりません: ' .. table.concat(missing, ', ') .. ' (Neovim 更新で要確認)')
  end
end)

---@param bufnr integer
local function reload(bufnr)
  if type(dir._reload) == 'function' then
    dir._reload(bufnr)
  end
end

--- 絶対パスに正規化する.
-- fnamemodify(x, ':p') はディレクトリなら末尾に "/" を付けるため,
-- そのまま連結や ':t' に渡すと dest が空文字になる (dir の貼り付けが全滅する).
---@param path string
---@return string
local function abspath(path)
  local abs = fn.fnamemodify(path, ':p')
  if #abs > 1 and abs:sub(-1) == '/' then
    abs = abs:sub(1, -2)
  end
  return abs
end

-- [[一覧カーソル行の解釈]]

--- カーソル行を一覧エントリとして解釈する.
---@return { path: string, is_dir: boolean }? @行が空/存在しないパスなら nil
local function cursor_entry()
  local line = api.nvim_get_current_line()
  if line == '' then
    return nil
  end
  local is_dir = line:sub(-1) == '/'
  local raw = (is_dir and line:sub(1, -2) or line):gsub('%z', '\n')
  if raw == '' then
    return nil
  end
  local path = abspath(raw)
  local isdir = fn.isdirectory(path) == 1
  if not isdir and fn.filereadable(path) == 0 then
    return nil
  end
  return { path = path, is_dir = isdir }
end

--- 操作対象のパスを返す. 使えないエントリなら理由を通知して nil.
---@param op string 通知文に載せるキー名
---@param need_file? boolean true ならディレクトリ行を弾く
local function target(op, need_file)
  local entry = cursor_entry()
  if not entry then
    warn(('%s: カーソル行が読み取れないか、存在しないパスです'):format(op))
    return nil
  end
  if need_file and entry.is_dir then
    warn(('%s: ディレクトリには使えません（<CR> で開けます）'):format(op))
    return nil
  end
  return entry.path
end

---@param bufnr integer
---@return string
local function current_dir(bufnr)
  return abspath(api.nvim_buf_get_name(bufnr))
end

--- 空のディレクトリか. 隠し要素も含めて数える ('.' と '..' は含まない).
---@param path string
---@return boolean
local function is_empty_dir(path)
  local entries = fn.glob(fn.escape(path, '') .. '/{,.[!.],..?}*', 0, true)
  return type(entries) == 'table' and #entries == 0
end

-- [[ファイル操作. 実際に変更したら true を返す (reload 判定に使う)]]

--- op を「fs を変えたときだけ一覧を再描画する」キーハンドラにする.
--- bufnr はここで閉じ込めておく. RHS 関数は Neovim が lhs 文字列を引数に呼ぶため,
--- 返した関数の引数として bufnr を受け取る形にすると 'zp' が bufnr になる.
---@param op fun(bufnr: integer): boolean
---@param bufnr integer
local function with_reload(op, bufnr)
  return function()
    if op(bufnr) then
      reload(bufnr)
    end
  end
end

---@param text string
---@return string? 空入力は nil
local function prompt(text)
  -- 第3引数 'file' でパス補完. 空白やクォートを含む名前の入力ミスが減る.
  local res = fn.input(text, '', 'file')
  if not res or res == '' then
    return nil
  end
  return res
end

local function create()
  local input = prompt('New file/folder: ')
  if not input then
    return false
  end
  local path = abspath(input)
  if fn.filereadable(path) == 1 or fn.isdirectory(path) == 1 then
    warn('既にあります: ' .. path)
    return false
  end
  if input:sub(-1) == '/' then
    -- fn.mkdir の戻り値: 1 = OK (Vim script の OK), 0 = 失敗, -2 = 既存 ('p' なしのとき)
    local rc = fn.mkdir(path, 'p')
    if rc ~= 1 then
      fail(('mkdir 失敗 (%d): %s'):format(rc, path))
      return false
    end
    return true
  end
  if fn.writefile({}, path) ~= 0 then
    fail('作成に失敗: ' .. path)
    return false
  end
  return true
end

--- dd: ファイルと空ディレクトリを消す. 中身のあるディレクトリは削除しない.
local function delete()
  local path = target('dd')
  if not path then
    return false
  end
  if fn.isdirectory(path) == 1 and not is_empty_dir(path) then
    warn('中身があるため削除できません: ' .. path)
    return false
  end
  local ok, why = os.remove(path)
  if not ok then
    fail(('削除に失敗 (%s): %s'):format(tostring(why), path))
    return false
  end
  return true
end

local function rename()
  local path = target('r')
  if not path then
    return false
  end
  local name = prompt('New name: ')
  if not name then
    return false
  end
  local dest = abspath(name)
  if dest == path then
    return false
  end
  -- os.rename (rename(2)) は既存ファイルを上書きするので明示的に弾く.
  if fn.filereadable(dest) == 1 or fn.isdirectory(dest) == 1 then
    warn('リネーム先が既にあります: ' .. dest)
    return false
  end
  local ok, why = os.rename(path, dest)
  if not ok then
    fail(('リネームに失敗 (%s): %s -> %s'):format(tostring(why), path, dest))
    return false
  end
  return true
end

-- 切り取り/コピー元. 一覧を移動しても失われないよう絶対パスで持つ.
---@type { src: string?, mode: ('cut'|'copy')? }
local clipboard = { src = nil, mode = nil }

local function clear_clipboard()
  clipboard = { src = nil, mode = nil }
end

---@param mode 'cut'|'copy'
---@param op string
---@return boolean fs は変えないので false (reload 不要)
local function set_clipboard(mode, op)
  local path = target(op)
  if not path then
    return false
  end
  clipboard = { src = path, mode = mode }
  vim.notify(('dir: %s %s'):format(mode == 'cut' and 'CUT:' or 'COPY:', path), LEVEL.INFO)
  return false
end

local function cut()
  return set_clipboard('cut', 'zd')
end

local function copy()
  return set_clipboard('copy', 'zy')
end

local function paste(bufnr)
  if not clipboard.src then
    warn('貼り付け元がありません（zd/zy で指定）')
    return false
  end
  local src = abspath(clipboard.src)
  if fn.filereadable(src) == 0 and fn.isdirectory(src) == 0 then
    warn('貼り付け元が消えています: ' .. src)
    clear_clipboard()
    return false
  end
  -- 末尾 "/" を落としてから :t なので, dir 名 "" で dest が化けない.
  local dest = abspath(current_dir(bufnr) .. '/' .. fn.fnamemodify(src, ':t'))
  if dest == abspath(fn.fnamemodify(src, ':.')) then
    warn('貼り付け先が同じディレクトリです: ' .. dest)
    return false
  end

  local changed = false
  if clipboard.mode == 'cut' then
    local ok, why = os.rename(src, dest)
    if not ok then
      fail(('貼り付け（移動）に失敗 (%s): %s'):format(tostring(why), src))
    else
      changed = true
    end
  else
    -- argv 形式なので名前に空白・クォートが含まれても問題ない. dir は -a で再帰複製.
    local flag = fn.isdirectory(src) == 1 and '-a' or '-f'
    fn.system({ 'cp', flag, src, dest })
    if vim.v.shell_error ~= 0 then
      fail(('貼り付け（複製）に失敗 (exit %d): %s -> %s'):format(vim.v.shell_error, src, dest))
    else
      changed = true
    end
  end
  -- 失敗時に状態を残すと, 同じ張りを貼り付け続けてしまうので成功時だけ消す.
  if changed then
    clear_clipboard()
  end
  return changed
end

-- [[ウィンドウ操作]]
-- util.win_split とほぼ同一の split() だが, このファイルは util に依存させない方針.
-- (window_set()/split() の差分検出ロジックは意図的な重複)

--- 現在のウィンドウ ID 集合を集合 (table) として返す.
---@return table<integer, true>
local function window_set()
  local set = {}
  for _, win in ipairs(api.nvim_list_wins()) do
    set[win] = true
  end
  return set
end

---@param winid integer window ID
---@param vertical boolean
---@param file? string 分割してできた新ウィンドウで開くファイル.
---   省略すると現バッファが複製され, 一覧バッファを閉じるときに両方のウィンドウが閉じる.
---@return integer? 新 window ID. 作られなければ nil.
local function split(winid, vertical, file)
  if winid == 0 then
    warn(('[dir.split] 対象ウィンドウが見つかりません: %s'):format(vim.inspect(winid)))
    return nil
  end
  local command = (vertical and 'vsplit' or 'split') .. (file and (' ' .. fn.fnameescape(file)) or '')
  local before_win_list = window_set()
  -- 第3引数 true = silent: 画面を書き換えず, 現ウィンドウとカーソル位置を維持する
  fn.win_execute(winid, command, true)
  -- 分割前後の window ID 集合の差分が新しいウィンドウ (既存ウィンドウの ID は不変)
  for _, win in ipairs(api.nvim_list_wins()) do
    if not before_win_list[win] then
      return win
    end
  end
  vim.notify('[dir.split] 新しいウィンドウが作られませんでした (switchbuf 等で既存ウィンドウに移動した可能性)',
    LEVEL.DEBUG)
  return nil
end

-- 現在ウィンドウを移動せず、winid に file を開く
local function open_in_win(file, winid)
  local buf = fn.bufadd(file)
  fn.bufload(buf)
  api.nvim_win_set_buf(winid, buf)
  vim.bo[buf].buflisted = true
end

-- dir バッファを閉じる（一覧バッファは unlisted にして unload する）.
-- buflisted は必ず bufnr 側で外す. vim.bo だと「カレント」を書き換える.
local function close_dir(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.bo[bufnr].buflisted = false
  api.nvim_buf_delete(bufnr, { unload = true })
end

-- 一覧を開く先のウィンドウ. 単一ウィンドウのとき winnr('#') は 0 で,
-- win_getid(0) も 0 なので、そのままでは split() が拒绝して zo/zv/zs が無反応になる.
local function target_win()
  local id = fn.win_getid(fn.winnr('#'))
  return id ~= 0 and id or api.nvim_get_current_win()
end

-- 現在カーソル上のファイルを Previous_window に開き、dir バッファを閉じる
local function open_and_close(bufnr)
  local file = target('zo', true)
  if not file then
    return
  end
  open_in_win(file, target_win())
  close_dir(bufnr)
end

-- 選択したファイルを垂直/水平分割したウィンドウで開く
local function split_open_and_close(bufnr, vertical)
  local op = vertical and 'zv' or 'zs'
  -- 分割前に弾く. 分割後に abort すると空ウィンドウが残る.
  local file = target(op, true)
  if not file then
    return
  end
  -- 開くファイルを split に渡すので, 新ウィンドウには一覧バッファが乗らない.
  local new_win_id = split(target_win(), vertical, file)
  if not new_win_id then
    return
  end
  close_dir(bufnr)
  api.nvim_set_current_win(new_win_id)
end

local function open_entry(bufnr)
  local entry = cursor_entry()
  if not entry then
    warn('<CR>: カーソル行が読み取れないか、存在しないパスです')
    return
  end
  if entry.is_dir then
    if type(dir._open_entry) ~= 'function' then
      fail('nvim.dir._open_entry がありません')
      return
    end
    return dir._open_entry()
  end
  open_and_close(bufnr)
end

-- [[キーマップ]]
-- 単一の定義からキー割り当てと ? ヘルプ文面の両方を作る（二重管理の防止）.
-- rhs(bufnr) が実際の RHS を返す. remap = true は <Plug> へ飛ぶものだけ.
-- KEYMAPS の内側から keymap_help を参照するには, 前方宣言が要る.
-- (後方にある local を_closure_ から見ると, コンパイル時にスコープ外でグローバル参照になり nil になる)
local keymap_help

local KEYMAPS = {
  {
    lhs = 'q',
    desc = '閉じる（一覧バッファを unload）',
    rhs = function(b)
      return function() close_dir(b) end
    end,
  },
  {
    lhs = 'o',
    desc = '新規作成（末尾 "/" でフォルダ）',
    rhs = function(b)
      return with_reload(create, b)
    end,
  },
  {
    lhs = 'r',
    desc = 'リネーム',
    rhs = function(b)
      return with_reload(rename, b)
    end,
  },
  {
    lhs = 'dd',
    desc = '削除（ディレクトリは空のときのみ）',
    rhs = function(b)
      return with_reload(delete, b)
    end,
  },
  {
    lhs = 'zd',
    desc = '切り取り（貼り付け元に指定）',
    rhs = function(b)
      return cut
    end,
  },
  {
    lhs = 'zy',
    desc = 'コピー（貼り付け元に指定）',
    rhs = function(b)
      return copy
    end,
  },
  {
    lhs = 'zp',
    desc = '貼り付け',
    rhs = function(b)
      return with_reload(paste, b)
    end,
  },
  {
    lhs = 'zo',
    desc = '開いて一覧を閉じる',
    rhs = function(b)
      return function() open_and_close(b) end
    end,
  },
  {
    lhs = 'zv',
    desc = '垂直分割で開いて一覧を閉じる',
    rhs = function(b)
      return function() split_open_and_close(b, true) end
    end,
  },
  {
    lhs = 'zs',
    desc = '水平分割で開いて一覧を閉じる',
    rhs = function(b)
      return function() split_open_and_close(b, false) end
    end,
  },
  {
    lhs = '<CR>',
    desc = 'ディレクトリを開く/ファイルを開いて一覧を閉じる',
    rhs = function(b)
      return function() open_entry(b) end
    end,
  },
  {
    lhs = '-', desc = '親ディレクトリへ（{count}- もOK）',
    remap = true, silent = true,
    rhs = function()
      return '<Plug>(nvim-dir-up)'
    end,
  },
  {
    lhs = '?',
    desc = 'キーマッピングを表示',
    rhs = function()
      return keymap_help
    end,
  },
}

--- KEYMAPS から ? ヘルプ文面を作る（desc と同じソース）.
keymap_help = function()
  local lines = { 'Key Mapping', '================' }
  for _, k in ipairs(KEYMAPS) do
    lines[#lines + 1] = ('%s: %s'):format(k.lhs, k.desc)
  end
  vim.notify(table.concat(lines, "\n"))
end

-- opts は bufnr ごとに新規生成するので、テーブルを共有して desc が混ざる事故がない.
local function setup_keymaps(bufnr)
  for _, k in ipairs(KEYMAPS) do
    -- rhs が関数のとき Neovim は lhs を引数に呼ぶので、bufnr を渡すための
    -- クロージャを rhs() が返す形にしている（KEYMAPS の q は close_dir そのもの不可）.
    map.set('n', k.lhs, k.rhs(bufnr), {
      buf = bufnr,
      desc = 'dir: ' .. k.desc,
      remap = k.remap == true,
      silent = k.silent == true,
    })
  end
end

map.set('n', '-', function()
  local win_id, _ = float_win.Create_floating_Window({ footer = "'?' open keymap in cmdline." })
  if win_id ~= false then
    vim.cmd("edit ./")
  end
end)

local augroup = api.nvim_create_augroup('DirPlugin', { clear = true })

api.nvim_create_autocmd('User', {
  pattern = 'DirReadPost',
  group = augroup,
  callback = function(args)
    vim.schedule(function()
      setup_keymaps(args.buf)
    end)
  end,
})

api.nvim_create_autocmd('FileType', {
  pattern = 'directory',
  group = augroup,
  callback = function()
    vim.bo.bufhidden = 'hide'
  end
})
```

```lua
-- util/floating_window.lua
local M = {}

local function isInteger(v)
  return type(v) == "number"
    and v == math.floor(v)        -- NaN は自己比較で false になるのでここで除外される
    and math.abs(v) ~= math.huge  -- ±inf を除外
end

local function validate_window_args(args)
  -- チェック順を保つため配列で定義
  local rules = {
    { name = "width",  value = args.width,  max = vim.o.columns, label = "window width"   },
    { name = "height", value = args.height, max = vim.o.lines,   label = "window lines"   },
    { name = "row",    value = args.row,    max = vim.o.lines,   label = "window lines"   },
    { name = "col",    value = args.col,    max = vim.o.columns, label = "window columns" },
  }

  local function fail(msg)
    vim.notify(msg, vim.log.levels.ERROR)
    return false
  end

  -- 1) 整数チェック
  for _, r in ipairs(rules) do
    if r.value ~= nil and not isInteger(r.value) then
      return fail(("Argument %s accepts integers only."):format(r.name))
    end
  end

  -- 2) 負数・上限チェック
  for _, r in ipairs(rules) do
    if r.value ~= nil then
      if r.value < 0 then
        return fail(("Argument %s must not be negative."):format(r.name))
      end
      if r.value > r.max then
        return fail(("Argument %s exceeds %s."):format(r.name, r.label))
      end
    end
  end

  -- 3) 文字列チェック (`''` と `nil` は許容する)
  local string_args = {
    { name = "title",  value = args.title },
    { name = "footer", value = args.footer },
  }
  for _, r in ipairs(string_args) do
    if r.value ~= nil and type(r.value) ~= "string" then
      return fail(("Argument %s accepts strings only."):format(r.name))
    end
  end

  return true
end

--- フローティングウィンドウを作成する関数
-- function M.Create_floating_Window(width, height, row, col, title, footer)
function M.Create_floating_Window(args)
  args = args or {}
  local width = args.width
  local height = args.height
  local row = args.row
  local col = args.col
  local title = args.title
  local footer = args.footer
  local result = validate_window_args({
    width = width,
    height = height,
    row = row,
    col = col,
    title = title,
    footer = footer,
  })
  if result ~= true then
    return false
  end

  -- 幅と高さ計算
  width = width or math.floor(vim.o.columns / 2)
  height = height or math.floor(vim.o.lines / 2)

  -- 位置計算
  row = row or math.floor(vim.o.lines / 4)
  col = col or math.floor(vim.o.columns / 4)

  -- タイトルとフッター設定
  title = title or ''
  footer = footer or ''

  local opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    title = title,
    footer = footer
  }

  -- バッファとウィンドウの生成
  local floating_buf = vim.api.nvim_create_buf(false, true)
  local floating_win_id = vim.api.nvim_open_win(floating_buf, true, opts)

  return floating_win_id, floating_buf
end

return M
```

