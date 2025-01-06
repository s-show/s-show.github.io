---
# type: docs 
title: Neovim でコマンドの実行結果をバッファに出力する方法
date: 2024-12-09T00:00:00+09:00
featured: false
draft: false
comment: true
toc: true
tags: [Neovim]
archives: 2024/12
---

## 前置き

Neovim でコマンドを実行したとき、実行結果が1行の文字列ならコマンドラインに結果が表示されるのですが、結果が Table 型だと `table 0x...` と表示されて中身を確認できません。

これではデバッグなどに支障をきたしますので、試行錯誤してコマンドの実行結果をバッファに出力させることに成功しましたので、その方法を備忘録としてまとめます。

## 実装方法

コマンドの実行結果が Table 型であっても、表示するだけなら `print()` と `vim.inspect()` を組み合わせれば表示させられます。以下のコードはその実例で、その下の画像は実行結果です。

```lua
lua print(vim.inspect(vim.api.nvim_get_autocmds({pattern={'Ddu:uiDone'}})))
```

{{< bsimage src="./img/result_in_commandline_window.png" title="" >}}

同じコマンドを `vim.inspect()` を使わずに実行した場合、実行結果はコマンドラインに `table: 0x...` と表示されます。

```lua
-- `vim.inspect()` を使わない場合の表示
lua print(vim.api.nvim_get_autocmds({pattern={'Ddu:uiDone'}}))
-> table: 0x7faa0fcb7978
```

ただ、この方法は、毎回 `lua print(vim.inspect(~~~))` と入力しなければならない上、何らかのキーをタイプすると結果が消えてしまいます。そこで、コマンド実行結果をバッファに出力させる方法を調べている時に発見した先例に従って、`nvim_create_user_command` を使って独自コマンドの `Redir` を作成し、その引数としてコマンド文字列を渡すと実行結果が新しいバッファで開かれるという形にしました。

最初に作った設定は以下のとおりです。

```lua
vim.api.nvim_create_user_command('Redir', function(ctx)
  local lines = vim.split(vim.fn.execute(ctx.args), '\n', { plain = true }))
  vim.cmd('new')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.opt_local.modified = false
end, { nargs = '+', complete = 'command' })
```

引数で渡されたコマンド文字列を `vim.fn.execute()` に渡して実行し、その結果を `vim.split()` で `nvim_buf_set_lines()` で処理できる形式に変換し、それから `vim.cmd('new')` で新しいバッファを作成したら `nvim_buf_set_lines()` でそのバッファに実行結果をセットしていました。

しかし、コマンド間違いなどで `vim.fn.execute()` の実行結果がエラーになると `vim.split()` に渡される値が `nil` になるようで、新しいバッファに何も表示されません。そこで、`vim.fn.execute()` の実行結果がエラーになったらエラーメッセージをバッファに表示させるため、以下のとおりコードを修正しました。

```lua
vim.api.nvim_create_user_command('Redir', function(ctx)
  local pcall_result, function_return = pcall(vim.fn.execute, ctx.args)
  vim.cmd('new')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(function_return, '\n', { plain = true }))
  vim.opt_local.modified = false
end, { nargs = '+', complete = 'command' })
```

最初の設定との違いは、`pcall` 関数を使ってエラーメッセージを `function_return` に格納するようにしたことです。こうすると `vim.fn.execute()` の実行結果がエラーになってもエラーメッセージが `function_return` に格納されて `vim.split()` で処理できますので、新しいバッファに何も表示されないという事態を避けられますし、エラーメッセージがバッファに出力されます。

## 実行例

```lua
Redir :=vim.api.nvim_get_autocmds({pattern={'Ddu:uiDone'}})
```

{{< bsimage src="./img/result_in_buffer.png" title="" >}}

```lua
-- `}` を1つ減らしてエラーになるようにしています
Redir :=vim.api.nvim_get_autocmds({pattern={'Ddu:uiDone'})
```

{{< bsimage src="./img/error_in_buffer.png" title="" >}}
