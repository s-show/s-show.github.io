---
# type: docs 
title: 日本語を分かち書きして Word Motion で移動できるようにしました
date: 2024-12-16T15:03:26+09:00
featured: false
draft: false
comment: true
toc: true
tags: [neovim,lua]
---

## 前置き

この記事はVim Advent Calendar 2024 の 16日目の記事です。本記事執筆時点で15日目の記事は登録されていないので、本記事の前の記事は、[nil2](https://zenn.dev/nil2) さんの [Vimの:{range}!を通して任意の言語でテキストを処理する](https://zenn.dev/nil2/articles/22a8960b84d46e) です。AWK でテキストを整形したりワンライナーのスクリプトのデバッグをするのに便利そうな手法ですね。

Vim/Neovim には単語単位で移動する Word Motion という機能があり、`w`, `b`, `e`, `ge` で単語単位の移動ができますが、スペースを単語の区切りとしていますので、日本語では使いにくい機能でした。

そんな中、Vim Advent Calendar 2024 の [2日目の記事](https://zenn.dev/sirasagi62/articles/d654fbbf5039d6)で [tinysegmenter.nvim](https://github.com/sirasagi62/tinysegmenter.nvim) という日本語の分かち書きを実現する Neovim プラグインが紹介されていましたが、こちらを利用すると日本語の文章を単語単位で簡単に区切れますので、これを使って Word Motion を改造してみようと思いました。

いざやってみると結構苦労しましたが、何とか形になりましたので、その成果を公表します。

## 実際の動作

<video class="video-shortcode" preload="auto" controls>
  <source src="https://github.com/s-show/s-show.github.io/raw/refs/heads/master/content/posts/2024-12-16/img/upgrade_word_motion_720p.MP4">
</video>

## 前提条件

```bash
❯ nvim --version
NVIM v0.10.1
Build type: Release
LuaJIT 2.1.1713773202
Run "nvim -V1 -v" for more info
```

[tinysegmenter.nvim](https://github.com/sirasagi62/tinysegmenter.nvim) で日本語を分かち書きしますので、事前にインストールします。私は [🚀 Getting Started | lazy.nvim](https://lazy.folke.io/) でプラグインを管理していますので、以下のコードを設定ファイルに追記して `Lazy` コマンドからインストールします。

```lua
return {
  "sirasagi62/tinysegmenter.nvim",
}
```

本記事執筆時点で使っている tinysegmenter.nvim のバージョンは次のとおりです。

```
tinysegmenter.nvim -> commit 64ac8a1
```

## 実装

まず、tinysegmenter.nvim で文章を分かち書きした結果を示します。

> 元の文章
> 今回は、2020年のアドベントカレンダーの記事で「設計中です」としていたキーボードについて、やっと自分なりに満足できる形になってきましたので、このキーボードの設計の意図なんかを書いていきます。
>
> 変換後の文章
> { "今回", "は", "、", "2", "0", "2", "0", "年", "の", "アドベントカレンダー", "の", "記事", "で", "「", "設計", "中", "です", "」", "と", "し", "て", "い", "た", "キーボード", "について", "、", "やっと", "自分", "なり", "に", "満足", "できる", "形", "に", "なっ", "て", "き", "まし", "た", "の", "で", "、", "この", "キーボード", "の", "設計", "の", "意図", "なんか", "を", "書い", "て", "いき", "ます", "。" }

この結果を見ながら Word Motion を改造します。改造は、以下の方針で実装しました。

- ASCII 文字の上にカーソルがある場合は本来の Word Motion をそのまま実行し、カーソルが日本語の文字の上にある時だけ改造した Word Motion を実行する。
    - Word Motion が上手く動かないのは日本語の上にカーソルがある場合なので、ASCII 文字の上にカーソルがある場合は本来の動作を実行してもらう。
- `W`, `B`, `E`, `gE` は改造しない。
    - これらは WORD 単位で動きますが、日本語における WORD 単位の挙動が思いつかなかったので、今回は改造を見送りました。
- `2w` のように回数を指定した場合、きちんと回数分だけモーションを繰り返す

また、実装を始めた時は、以下のようにコード中の変数と `w`, `b`, `e`, `ge` をタイプしたときに移動するべき場所を文字毎にまとめた表を作成して、正しく改造できているかすぐに確認できるようにしました。

|                     | 今 | 回 | は | 、 | 2 | 0 | 2 | 0 | 年 | の | ア | ド | ベ | ン | ト | カ | レ | ン | ダ | ー | の | … | い | き | ま | す | 。 |
|---------------------|----|----|----|----|---|---|---|---|----|----|----|----|----|----|----|----|----|----|----|----|----|---|----|----|----|----|----|
| length_up_to_cursor | 2  | 2  | 3  | 4  | 5 | 6 | 7 | 8 | 9  | 10 | 20 | 20 | 20 | 20 | 20 | 20 | 20 | 20 | 20 | 20 | 21 | … | 93 | 93 | 95 | 95 | 96 |
| cursor_position     | 1  | 2  | 3  | 4  | 5 | 6 | 7 | 8 | 9  | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | … | 92 | 93 | 94 | 95 | 96 |
| w                   | 　 | 　 | ●  | ●  | ● | ● | ● | ● | ●  | ●  | ●  |    |    |    |    |    |    |    |    | 　 | ●  | … | ●  | 　 | ●  | 　 | ●  |
| b                   | ●  | 　 | ●  | ●  | ● | ● | ● | ● | ●  | ●  | ●  |    |    |    |    |    |    |    |    | 　 | ●  | … | ●  | 　 | ●  | 　 | 　 |
| e                   | 　 | ●  | ●  | ●  | ● | ● | ● | ● | ●  | ●  | 　 |    |    |    |    |    |    |    |    | ●  | ●  | … | 　 | ●  | 　 | ●  | 　 |
| ge                  | 　 | ●  | ●  | ●  | ● | ● | ● | ● | ●  | ●  | 　 |    |    |    |    |    |    |    |    | ●  | ●  | … | 　 | ●  | 　 | ●  | 　 |

ここまで準備してから実装を始めましたが、カーソル位置と分かち書きの結果を対応させる必要がありましたので、試行錯誤の末、分かち書きの結果を以下のような多次元配列に格納しました。この多次元配列を `for` 文で順番に処理しつつ、`getcursorcharpos()` 関数で取得したカーソル位置と比較することで、カーソル位置と分かち書きの結果を対応させることにしました。

```lua
{
    {
        ['text'] = '今回',
        ['start'] = 1,
        ['end'] = 2
    },
    {
        ['text'] = 'は',
        ['start'] = 3,
        ['end'] = 3
    },
    {
        ['text'] = '、',
        ['start'] = 4,
        ['end'] = 4
    },
}
```

また、本来の `w`, `b`, `e`, `ge` は行を跨いだ移動もできますので、以下のようにアルファベットだけの文章での `w`, `b`, `e`, `ge` の動きをチェックしてから、日本語の文章でも同様の動きになるよう調整しました（|はカーソル位置を示しています）。

```lua
-- アルファベットだけの文章
if vim.fn.strcharlen(char) > 1 |then
  return false
end

- `w` をタイプ
if vim.fn.strcharlen(char) > 1 then
  |return false
end

-- `b` をタイプ
if vim.fn.strcharlen(char) > |1 then
  return false
end

-- `e` をタイプ
if vim.fn.strcharlen(char) > 1 the|n
  return false
end

-- `ge` をタイプ
if vim.fn.strcharlen(char) > |1 then
  return false
end

-- 日本語の文章
今回は、2020年のアドベントカレンダーの|記事
    で設計中ですとしていたキーボードについて、

- `w` をタイプ
今回は、2020年のアドベントカレンダーの記事
    |で設計中ですとしていたキーボードについて、

- `b` をタイプ
今回は、2020年のアドベントカレンダー|の記事
    で設計中ですとしていたキーボードについて、

-- `e` をタイプ
今回は、2020年のアドベントカレンダーの記|事
    で設計中ですとしていたキーボードについて、

-- `ge` をタイプ
今回は、2020年のアドベントカレンダー|の記事
    で設計中ですとしていたキーボードについて、
```

実はこの行を跨いだ移動の実装が面倒だったところで、行頭・行末に空白文字がある場合の処理が難しかったです。試行錯誤の結果、分かち書きは行頭・行末の空白文字を除いた文章で実施し、同時に行頭で空白文字以外の文字が最初に登場する場所と、行末で空白文字以外の文字が最後に登場する場所を変数に格納して利用する形にしました。

## 実際のコード

```lua
local tinysegmenter = require("tinysegmenter")

-- @desc: 引数で渡された文字が ASCII 文字かそうでないか判断する関数
-- @param - string
function IsASCIIChar(char)
  if vim.fn.strcharlen(char) > 1 then
    return false
  end
  local char_byte_count = string.len(char)
  if char_byte_count == 1 then
    return true
  else
    return false
  end
end

function OverrideWordMotion(arg)
  if IsASCIIChar(arg.under_cursor_char) then
    -- `bang = true` とすると `normal!` と同じことになる
    -- カーソルがASCII文字の上にあるときは、通常の `w`, `b`, `e`, `ge` を実行する。
    vim.cmd.normal({ arg.motion, bang = true })
  else
    local parsed_text_with_position = {}
    local text_start_position = 1
    for i, text in ipairs(arg.parsed_text) do
      parsed_text_with_position[i] = {}
      parsed_text_with_position[i]['text'] = text
      parsed_text_with_position[i]['start'] = text_start_position
      parsed_text_with_position[i]['end'] = text_start_position + vim.fn.strcharlen(text) - 1
      text_start_position = text_start_position + vim.fn.strcharlen(text)
    end
    for i, text_with_position in ipairs(parsed_text_with_position) do
      if arg.cursor_position[3] >= text_with_position['start'] + arg.first_char_position - 1 and
         arg.cursor_position[3] <= text_with_position['end']   + arg.first_char_position - 1 then
        if arg.motion == 'w' then
          -- カーソルが非空白文字の末尾 or 分かち書きした文字列の最後のノードにある
          if arg.cursor_position[3] == arg.last_char_position or
            text_with_position['end'] + arg.first_char_position - 1 == arg.last_char_position then
            local below_line_text = vim.fn.getline(arg.cursor_position[2] + 1)
            local first_char_position = vim.fn.matchstrpos(below_line_text, '^\\s\\+')[3] + 1
            arg.cursor_position[3] = first_char_position
            arg.cursor_position[2] = arg.cursor_position[2] + 1
          elseif i ~= #parsed_text_with_position then
            arg.cursor_position[3] = parsed_text_with_position[i + 1]['start'] + arg.first_char_position - 1
          end
        end
        if arg.motion == 'ge' then
          -- カーソルが非空白文字の始め or 分かち書きした文字列の最初のノードにある
          if arg.cursor_position[3] == arg.first_char_position or
            text_with_position['start'] + arg.first_char_position - 1 == arg.first_char_position then
            local above_line_text = vim.fn.getline(arg.cursor_position[2] - 1)
            local last_char_position = vim.fn.strcharlen(vim.fn.substitute(above_line_text, '\\s\\+\\_$', '', 'g'))
            arg.cursor_position[3] = last_char_position
            arg.cursor_position[2] = arg.cursor_position[2] - 1
          elseif i ~= 1 then
            arg.cursor_position[3] = parsed_text_with_position[i - 1]['end'] + arg.first_char_position - 1
          end
        end
        if arg.motion == 'b' then
          -- カーソルが非空白文字の始めにある
          if arg.cursor_position[3] == arg.first_char_position then
            local above_line_text = vim.fn.getline(arg.cursor_position[2] - 1)
            local above_line_text_without_space = vim.fn.substitute(above_line_text, '\\s\\+\\_$', '', 'g')
            local above_line_text_without_space_length = vim.fn.strcharlen(above_line_text_without_space)
            local parsed_above_line_text = tinysegmenter.segment(above_line_text_without_space)
            arg.cursor_position[3] = above_line_text_without_space_length - vim.fnstrcharlen(parsed_above_line_text[#parsed_above_line_text]) + 1
            arg.cursor_position[2] = arg.cursor_position[2] - 1
          -- カーソルが分かち書きした文字列の最初のノードにある
          elseif text_with_position['start'] + arg.first_char_position - 1 == arg.first_char_position then
            arg.cursor_position[3] = text_with_position['start'] + arg.first_char_position - 1
          elseif i ~= 1 then
            -- カーソルが分かち書きした各ノードの1文字目にある
            if arg.cursor_position[3] == text_with_position['start'] + arg.first_char_position - 1 then
              arg.cursor_position[3] = parsed_text_with_position[i - 1]['start'] + arg.first_char_position - 1
            else
              arg.cursor_position[3] = text_with_position['start'] + arg.first_char_position - 1
            end
          end
        end
        if arg.motion == 'e' then
          -- カーソルが非空白文字の末尾にある
          if arg.cursor_position[3] == arg.last_char_position then
            local below_line_text = vim.fn.getline(arg.cursor_position[2] + 1)
            local below_line_text_without_space = vim.fn.substitute(below_line_text, '^\\s\\+', '', 'g')
            local first_char_position = vim.fn.matchstrpos(below_line_text, '^\\s\\+')[3] + 1
            -- 行頭に空白が無いと first_char_position が 0 になるので、強制的に値を 1 にする
            if first_char_position == 0 then
              first_char_position = first_char_position + 1
            end
            local parsed_below_line_text = tinysegmenter.segment(below_line_text_without_space)
            arg.cursor_position[3] = vim.fn.strcharlen(parsed_below_line_text[1]) + first_char_position - 1
            arg.cursor_position[2] = arg.cursor_position[2] + 1
            -- カーソルが分かち書きした文字列の最後のノードにある
          elseif text_with_position['end'] + arg.first_char_position - 1 == arg.last_char_position then
            arg.cursor_position[3] = text_with_position['end'] + arg.first_char_position - 1
          elseif i ~= #parsed_text_with_position then
            -- カーソルが分かち書きした各ノードの最後の文字にある
            if arg.cursor_position[3] == text_with_position['end'] + arg.first_char_position - 1 then
              arg.cursor_position[3] = parsed_text_with_position[i + 1]['end'] + arg.first_char_position - 1
            else
              arg.cursor_position[3] = text_with_position['end'] + arg.first_char_position - 1
            end
          end
        end
        vim.fn.setcursorcharpos(arg.cursor_position[2], arg.cursor_position[3])
        break
      end
    end
  end
end

for _, motion in ipairs({'w', 'b', 'e', 'ge'}) do
  vim.keymap.set('n', motion, function ()
    -- コマンドの指定回数を取得する。回数が指定されていない場合の値は 1 である。
    local count1 = vim.v.count1
    while count1 > 0 do
      local cursor_line_text = vim.fn.getline('.')
      -- 行末の空白文字を残して分かち書き処理すると後処理が面倒なので削除する
      local cursor_line_text_without_eol_space = vim.fn.substitute(cursor_line_text, '\\s\\+\\_$', '', 'g')
      -- 行頭の空白文字も残すと後処理が面倒なので削除する
      local cursor_line_text_without_space = vim.fn.substitute(cursor_line_text_without_eol_space, '^\\s\\+', '', 'g')
      -- `b`, `ge` はカーソルが非空白文字の始めにあれば処理を分岐するので、非空白文字の始めの位置を取得しておく。
      -- matchstrpos はパターンが1文字目に見つかったらインデックスを `0` `と返す
      local first_char_position = vim.fn.matchstrpos(cursor_line_text, '^\\s\\+')[3] + 1
      -- 行頭に空白が無いと first_char_position が 0 になるので、強制的に値を 1 にする
      if first_char_position == 0 then
        first_char_position = first_char_position + 1
      end
      -- `w`, `e` はカーソルが非空白文字の末尾にあれば処理を分岐するので、非空白文字の末尾の位置を取得しておく。
      local last_char_position = vim.fn.strcharlen(cursor_line_text_without_eol_space)
      local parsed_text = tinysegmenter.segment(cursor_line_text_without_space)
      local under_cursor_char = vim.fn.matchstr(cursor_line_text, '.', vim.fn.col('.')-1)
      local cursor_position = vim.fn.getcursorcharpos()
      OverrideWordMotion({
        motion = motion,
        cursor_line_text = cursor_line_text,
        parsed_text = parsed_text,
        cursor_position = cursor_position,
        under_cursor_char = under_cursor_char,
        first_char_position = first_char_position,
        last_char_position = last_char_position
      })
      count1 = count1 - 1
    end
  end)
end
```

## 実装中に知った機能など

### `vim.cmd.normal` で `normal!` と同じ動作を実現する方法

`vim.cmd.normal` の引数に `bang = true` を渡すと、`normal` ではなく `normal!` と同じ意味になります。

これを活用することで、`vim.cmd[[normal! w]]` としていた部分を `vim.cmd.normal({motion_type_variable, bang = true})` に変更できました。

### `2w` のような回数指定の回数を取得する方法

回数を指定していたらその回数だけ処理を繰り返すという機能を実現したかったのですが、`vim.v.count1` に指定された回数が保存されていることが分かりましたので、この変数を使いました。回数が指定されていない場合のデフォルト値は `1` です。

### テーブル型変数の最後の要素にアクセスする方法

Lua にはテーブルの末尾にアクセスするメソッドはないようですが、`#変数名` とすればテーブルの配列数を取得できますので、`hoge_table` というテーブル型の変数の最後の要素にアクセスするには `hoge_table[#hoge_table]` とすれば良いことが分かりました。

### 文字列の置き換え

カーソル行の行末にある空白文字を削除する必要がありましたが、Lua の文字列置き換え関数では UTF-8 の文字列を適切に扱えないため、代わりに Vim/Neovim のビルトイン関数の `substitute()` を使うことにしました。

行末の空白文字を削除するには `vim.fn.substitute(vim.fn.getline('.'), '\\s\\+\\_$', 'g')` とすればOKです。

なお、行頭の空白文字を削除するには `vim.fn.substitute(vim.fn.getline('.'), '^\\s\\+', '', 'g')` とすればOKです。

## 未実装の機能

行を跨ぐ「アルファベットから日本語」、「日本語からアルファベット」への移動について、前者は通常の `w`, `b`, `e`, `ge` で処理し、後者は tinysegment で分かち書きした結果に基づいて移動するため、あるべき移動からずれた移動になることがあります。

これに対応するのは難しそうなので、現時点では対応していません。
