---
# type: docs 
title: Neovim の Lua で文字列の長さを取得しようとしたら苦労した話
date: 2024-12-14T00:36:47+09:00
featured: false
draft: false
comment: true
toc: false
tags: [Neovim,Lua]
---

{{% alert info %}}
2024年12月15日追記あり
{{% /alert %}}

## 前置き

[tinysegmenter.nvim](https://zenn.dev/sirasagi62/articles/d654fbbf5039d6) という Lua で日本語の分かち書きを実現するソフトウェアが登場しましたので、これを利用して、Neovim の Word Motion をオーバーライドしようと思ったのですが、その処理で日本語を含む文字列の長さを取得する必要が生じました。

最初は簡単にできるだろうと考えていたのですが、いざやってみるとハマってしまったので、失敗した方法と成功した方法を備忘録として残します。

## 実装例

まず、失敗したコードを示します。いずれのコードでも日本語1文字が1文字とカウントされていません。

```lua
print(string.len('ああ'))
-> 6
```

```lua
local M = {}
for char in string.gmatch('ああ', '.?') do
  table.insert(M, char)
end
print(#M)
-> 6
```

```vim
:echo strlen('ああ')
-> 6
```

一方、処理する文字列が ASCII 文字だと、同じコードでも1文字が1文字とカウントされます。

```lua
print(string.len('aa'))
-> 2
```

```lua
local N = {}
for char in string.gmatch('aa', '.?') do
  table.insert(N, char)
end
print(#N)
-> 2
```

```vim
:echo strlen('aa')
-> 2
```

処理する文字列が ASCII 文字か否かで結果が変わってしまうのですが、日本語の文字の長さが ASCII 文字の3倍になっているので、文字コードが原因ではないかと仮定しました。

そこで、この仮説を踏まえて以下のコードを実行したところ、`<e3>`、`<81>`、`<82>`、`<e3>`、`<81>`、`<84>` という結果が得られました。これは `あ` の utf8 コードの `E38182` の 1バイト目・2バイト目・3バイト目、`い` の utf8 コードの `E38184` 1バイト目・2バイト目・3バイト目がそれぞれ取り出されていると思われます。つまり、`string` は文字列を ASCII 文字として取り扱っているものと思われます。

```lua
vim.notify(string.sub('ああ', 1, 1))
vim.notify(string.sub('ああ', 2, 2))
vim.notify(string.sub('ああ', 3, 3))
vim.notify(string.sub('いい', 1, 1))
vim.notify(string.sub('いい', 2, 2))
vim.notify(string.sub('いい', 3, 3))
```

さらに、`string` に代えて `utf8` で文字列を処理すると日本語の文字列が正しく処理されましたので、`string` が文字列を一律に ASCII 文字として扱っているのは間違いなさそうです。

```lua
print(utf8.len('ああ'))
-> 2
```

```lua
local U = {}
for code in utf8.codes('ああ') do
  table.insert(U, code)
end
print(#U)
-> 2
```

よって、`string` の代わりに `utf8` で処理すれば日本語の文字も正しく処理できるのですが、`utf8` はバージョン 5.3 で導入された機能であり、バージョン 5.1 の Lua を使う Neovim では使えません。

（`utf8` がバージョン 5.3 で導入されたことは [Lua 5.3 readme](https://www.lua.org/manual/5.3/readme.html) で確認できます）

そこで、文字列を1文字ずつ分解して配列に格納し、その配列の長さを取得すれば文字列の長さを正しく取得できるのはないかと考えました。幸い、Neovim のビルトイン関数の `split()` は日本語の文字であっても1文字ずつ分解した結果を返してくれますので、`split()` と同じ組込み関数である `len()` と組み合わせて正しい文字列の長さを得ることができました。

```lua
vim.fn.len(vim.fn.split('ああ', '\\zs'))
-> 2
```

これで日本語の文字列の長さを正しく取得することができるようになりましたので、[tinysegmenter.nvim](https://zenn.dev/sirasagi62/articles/d654fbbf5039d6) を使って Neovim の Word motion をオーバーライドする方法を次の記事で紹介します。

### 追記（2024年12月15日）

本記事を公開した後、vim-jp で `strcharlen()` を使う方法を提案されましたので、以下のコードでテストしたら簡単に日本語の文字列の長さを取得できました。そのため、上記の `vim.fn.len(vim.fn.split('ああ', '\\zs'))` のようなコードを書かなくても、`vim.fn.strcharlen('ああ')` と書けば正しい文字列の長さを取得できます。

```vim
:echo strcharlen('ああ')
-> 2
```

## 補足

`print(string.len('ああ'))` の結果が `6` になることを応用すると、カーソル下の文字が ASCII 文字か否かを判断できます。以下のユーザー関数は、カーソル下の文字が ASCII 文字であれば `true` を、それ以外の文字であれば `false` を返します。

```lua
function IsASCIIChar()
  local char_byte_count = string.len(vim.fn.matchstr(vim.fn.getline('.'), '.', vim.fn.col('.')-1))
  if char_byte_count == 1 then
    return true
  else
    return false
  end
end
```

関数の処理内容は、まず、`vim.fn.matchstr(vim.fn.getline('.'), '.', vim.fn.col('.')-1)` でカーソル下の文字を取得します。それから、取得した文字の長さを `string.len()` で取得して `char_byte_count` 変数に格納します。取得した文字が ASCII 文字であれば長さは `1` になり、ASCII 文字以外であれば長さは `1` より大きくなります。

そして、`char_byte_count` 変数の値が `1` なら ASCII 文字と判定し、`1` でなければ ASCII 文字ではないと判定します。

## 蛇足

`split('ああ', '\\zs')` というコードですが、これは、[vimrc - How should I split a string with no spaces in vim script? - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/189215/how-should-i-split-a-string-with-no-spaces-in-vim-script) というサイトで見つけました。

また、AI を活用した有料検索サイトの [Kagi search](https://kagi.com) で「vim string split」と検索して、ヒットしたページの要約を作成してくれる Quick Answer を使ったところ、上記のページの要約として同じコードが紹介されました。

この Quick Answer は便利なサービスで、これまでは Google 検索の結果がイマイチだったので [DuckDuckGo](https://duckduckgo.com/) を使っていたのですが、最近は [Kagi search](https://kagi.com) を使うことも増えてきました。最初は有料版の機能をお試しで使うこともできますので、一度使ってみることをオススメします。

