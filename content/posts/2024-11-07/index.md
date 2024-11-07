---
# type: docs 
title: Windows Terminal + WSL2 + Neovim で Autolist.nvim を使う場合のメモ
date: 2024-11-07T21:35:09+09:00
featured: false
draft: false
comment: true
toc: false
tags: [neovim]
---

## 問題の内容

箇条書きの各行の末尾で改行したら自動的に `- ` を追加して欲しいので、`vim.keymap.set("i", "<S-CR>", "<CR><cmd>AutolistNewBullet<cr>")` というキーバインドを設定しましたが、`Shift-Enter` をタイプしても単なる改行になっていました。

```md
// 期待する動作
- hogehoge⏎ ← 末尾で改行したら
- |         ← 自動的に `- ` を挿入してカーソルの位置を整えて欲しい

// 実際の動作
- hogehoge⏎ ← 末尾で改行したら
|           ← 単なる改行になってカーソルが行頭に来る
```

`<S-CR>` を別のキーバインドに変更すると期待通りの動作になる上、他の機能はキチンと動作することから、プラグインの設定は問題ないと思われるのですが、`<S-CR>` だけが上手く動かない状態でした。

## 解決策

同様の問題が起きていないか調べたところ、`Shift-Enter` にキーバインドを割り当てても動かないという問題を複数見つけました。それらの問題への回答によると、この問題は Vim の問題ではなく、ターミナルが受け取ったキー入力をシェルに渡す部分での問題ということでした。そのため、ターミナルに対して、`Shift-Enter` を受け取ったらシェルに `Shift-Enter` を渡すよう設定する必要があるとのことでした。

幸いなことに、回答の中にターミナル毎の設定例が記載されており、Windows Terminal の設定例もありましたので、そちらを拝借して設定ファイルの `actions` に次のとおり設定を追加しました。

```json
{
    "actions": 
    [
        {
            "command": 
            {
                "action": "sendInput",
                "input": "\u001b[13;2u"
            },
            "id": "User.sendInput.8882FD6D"
        },
        {
            "command": 
            {
                "action": "sendInput",
                "input": "\u001b[13;5u"
            },
            "id": "User.sendInput.F8A79DCB"
        }
    ],

```

これで期待通りの動作を実現することができました。

```md
// 実現できた動作
- hogehoge⏎ ← 末尾で改行したら
-           ← 自動的に `- ` が挿入される
```

なお、現在の設定は次のとおりです。[lazy.nvim](https://github.com/folke/lazy.nvim) を使ってプラグインを管理しているので、`/lua/plugin/autolist-nvim.lua` という名前で設定ファイルを作成しています。

```lua
return {
  {
    "gaoDean/autolist.nvim",
    ft = {
      "markdown",
      "text",
      "tex",
      "plaintex",
      "norg",
    },
    config = function()
      require("autolist").setup()

      vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
      vim.keymap.set("i", "<S-tab>", "<cmd>AutolistShiftTab<cr>")
      vim.keymap.set("i", "<C-t>", "<c-t><cmd>AutolistRecalculate<cr>") -- an example of using <c-t> to indent
      vim.keymap.set("i", "<S-CR>", "<CR><cmd>AutolistNewBullet<cr>")
      vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
      vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
      vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<cr><CR>")
      vim.keymap.set("n", "<C-r>", "<cmd>AutolistRecalculate<cr>")

      vim.keymap.set("n", "<leader>cn", require("autolist").cycle_next_dr, { expr = true })
      vim.keymap.set("n", "<leader>cp", require("autolist").cycle_prev_dr, { expr = true })

      vim.keymap.set("n", ">>", ">><cmd>AutolistRecalculate<cr>")
      vim.keymap.set("n", "<<", "<<<cmd>AutolistRecalculate<cr>")
      vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>")
      vim.keymap.set("v", "d", "d<cmd>AutolistRecalculate<cr>")
    end,
  },
}
  ```

## 参考にしたサイト

[vim - How to map Shift-Enter - Stack Overflow](https://stackoverflow.com/questions/16359878/how-to-map-shift-enter)
