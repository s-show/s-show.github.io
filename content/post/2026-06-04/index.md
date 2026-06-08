---
title: "Rio Terminal + WSL2 + tmux で Neovim に ctrl-shift-w を認識させる方法" # Title of the blog post.
date: 2026-06-04T20:21:06+09:00 # Date of post creation.
description: "Rio terminal + tmux + Neovim で `Ctrl + Shift + W` のキーバインドを設定する方法" # Description used for search engine.
featured: false
draft: false
comment: true
toc: false
tags: [Neovim, tmux, Rio Terminal]
archives: 2026/6
---

## 前置き

Neovim のウィンドウ切り替えに [tkmpypy/chowcho.nvim](https://github.com/tkmpypy/chowcho.nvim) というプラグインを使っており、ウィンドウの数に応じて、`<C-w>w` に2つの処理を割り当てていました。

- ウィンドウが2つならウィンドウを切り替える（Neovim 標準のウィンドウ切り替え）
- ウィンドウが3つ以上なら chowcho.nvim によるウィンドウ切り替えを起動する

ただ、`<C-w>w` だとキーを二連打する必要がありますが、`<C-S-w>` にこの処理を割り当てたら二連打しなくても OK では？と思い実装してみることにしました。

しかし、Rio terminal + WSL2 + tmux + Neovim でこの希望を実現するには一工夫する必要がありましたので、その方法を備忘録として残します。

## 環境

```bash
> uname -a
Linux desktop 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 GNU/Linux
```

```bash
nix-shell -p nix-info --run "nix-info -m"
 - system: `"x86_64-linux"`
 - host os: `Linux 6.6.114.1-microsoft-standard-WSL2, NixOS, 26.05 (Yarara), 26.05.20260328.b63fe7f`
 - multi-user?: `yes`
 - sandbox: `yes`
 - version: `nix-env (Nix) 2.31.3`
 - channels(root): `"nixos-24.11, nixos-wsl"`
 - nixpkgs: `/nix/store/6v4frqfyqmw34z3v0av13z0890w3lmjx-source`
```

```
> rio.exe --version
rioterm 0.4.4
```

```bash
> tmux -V
tmux 3.6a
```


## 試行錯誤の過程

まず、Neovim に以下の設定を追加しましたが、`<C-S-w>` を押しても反応がありませんでした。

```lua
vim.keymap.set({ 'n', 't' }, "<C-S-w>", function()
  local result, _ = pcall(require, 'chowcho')
  if not result then
    vim.api.nvim_command('wincmd w')
    return
  else
    local wins = 0
    for i = 1, vim.fn.winnr('$') do
      local win_id = vim.fn.win_getid(i)
      local conf = vim.api.nvim_win_get_config(win_id)
      if conf.focusable then
        wins = wins + 1
        if wins > 2 then
          chowcho.run()
          return
        end
      end
    end
    vim.api.nvim_command('wincmd p')
  end
end)
```

そこで Claude に相談したところ、キーの伝達経路に問題があると回答されました。

## 原因

キーの伝達経路といっても何のことかとなりますが、要は、ユーザーが入力したキーが Rio Terminal → WSL2 → tmux → Neovim と順番に送信される過程のことです。

そして、「キーの伝達経路に問題がある」という回答の具体的な内容は、Rio Terminal が Shift キーを無視してしまうため、Rio Terminal に `Ctrl + Shift + w` を入力しても WSL2 には `Ctrl + w` しか届かないというものです。

これを確かめるには、まず tmux を起動していない状態で `cat -v` を実行してから、`ctrl + shift + w` と `ctrl + w` を入力します。もし、Shift キーが認識されていれば `ctrl + shift + w` と `ctrl + w` で出力が変わるはずですが、Shift キーが認識されていなければ `ctrl + shift + w` と `ctrl + w` で同じ出力になります。

この Shift キーが認識されない問題は歴史的経緯によるものなので、

そのため、`<C-S-w>` のような `Ctrl + Shift + キー` の組み合わせを正しく認識させるには、CSI-u（Kitty Keyboard Protocol）形式でエンコードされたシーケンスを Rio → tmux → Neovim の各段階で確実に渡していく必要があります。

## 解決策

### Rio terminal の設定

Rio は `Ctrl + Shift + W` を CSI-u 形式でネイティブに送出できませんので、Rio の `config.toml` に以下の設定を追加し、`ctrl + shift + w` を押すと CSI-u 形式のエスケープシーケンスが送信されるようにします。かなり無理矢理な方法ですが、これで Rio terminal 側は何とかなります。

また、`Ctrl + Shift + W` はデフォルトで Rio のタブを閉じるアクション（`CloseTab`）に割り当てられているため、まず無効化し、それからエスケープシーケンス送信を設定します。

なお、問題の原因を探る過程では、`ctrl + shift + w` に加えて `ctrl + shift + ` の別のキーの組み合わせもテストしています。

```toml
[bindings]
keys = [
  # Ctrl + Shift + W のデフォルトアクション（CloseTab）を無効化
  { key = "w", with = "control | shift", action = "None" },
  # CSI-u 形式のエスケープシーケンスを直接送信する
  { key = "w", with = "control | shift", esc = "\u001b[119;6u" }
]
```

エスケープシーケンスの送信については、`esc` [フィールド](https://rioterm.com/docs/key-bindings#esc) にエスケープシーケンスをハードコードしています。`\u001b[119;6u` は CSI-u における `w`（文字コード 119）と `Ctrl-Shift`（modifier 値 6）を組み合わせたシーケンスです。

### tmux の設定

ターミナルからの拡張キー入力を受け付けるため、`tmux.conf` に以下の設定を追加します。

```
set -s extended-keys always
set -as terminal-features '*:extkeys'
set -s extended-keys-format csi-u
```

それぞれの設定の内容は以下のとおりです。

#### set -s extended-keys always

この設定は、ターミナルからの拡張キー入力を常に受け付ける（接続元ターミナルの応答に基づく判定の失敗による取りこぼしを防ぐ）ためのものです。このオプションについては、tmux の man ページで以下のとおり説明されています（改行と空白は調整して引用。以下同じ）。

> extended-keys [on | off | always]
> 
> Controls how modified keys (keys pressed together with Control, Meta, or Shift) are reported. This is the equivalent of the modifyOtherKeys xterm(1) resource.
> When set to on, the program inside the pane can request one of two modes:
>   mode 1 which changes the sequence for only keys which lack an existing well-known representation;
>   or mode 2 which changes the sequence for all keys.
> When set to always, modes 1 and 2 can still be requested by applications, but mode 1 will be forced instead of the standard mode.
> When set to off, this feature is disabled and only standard keys are reported.
> 
> tmux  will  always request extended keys itself if the terminal supports them.  See also the extkeys feature for the terminal-features option, the extended-keys-format option and
> the pane_key_mode variable. 
>
> （拙訳）
> extended-keys [on | off | always]
>
> このオプションは、装飾されたキー（Control, Meta, または Shiftキーと一緒に押されたキー）がどのようにレポートされるかコントロールするものです。これは、xterm(1) の modifyOtherKeys リソースと同等のものです。
> 
> on の場合、ペインの内部のプログラムは2つのモードのうち1つをリクエストできます: モード1は、既存の標準的なエスケープシーケンスが無いキーだけシーケンスを変更するモードで、モード2は全てのキーでシーケンスを変更するモードです。
> always の場合、アプリケーションは引き続きモード1またはモード2を要求できますが、標準モードの代わりにモード1が強制されます。
> off の場合、この機能は無効化され、通常のキーだけがレポートされます。
> 
> ターミナルが拡張キーをサポートしていれば、tmux は常に自身で拡張キーを要求します。terminal-features オプションの extkeys 機能、extended-keys-format オプション、および pane_key_mode 変数も参照してください。
>

この説明をまとめると、下表のようになります。

| 設定値 | アプリがmode 1を要求 | アプリがmode 2を要求 | アプリが何も要求しない |
|---|---|---|---|
| `off` | 無視（標準モード） | 無視（標準モード） | 標準モード |
| `on` | mode 1 | mode 2 | 標準モード |
| `always` | mode 1 | **mode 1**（mode 2を却下） | **mode 1**（強制） |

#### set -as terminal-features '*:extkeys'

このオプションは、接続元のターミナル名（$TERM）に関係なく拡張キー対応端末として強制認識させる設定です。このオプションの man ページの説明は以下のとおりです。

> terminal-features[] string
> 
> Set terminal features for terminal types read from terminfo(5). tmux has a set of named terminal features. Each will apply appropriate changes to the terminfo(5) entry in use.
> tmux can detect features for a few common terminals; this option can be used to easily tell tmux about features supported by terminals it cannot detect.
> The terminal-overrides option allows individual terminfo(5) capabilities to be set instead, terminal-features is intended for classes of functionality supported in a standard way but not reported by terminfo(5).
> Care must be taken to configure this only with features the terminal actually supports.
> 
> This is an array option where each entry is a colon-separated string made up of a terminal type pattern (matched using glob(7) patterns) followed by a list of terminal  features.
> The available features are:
> 
> extkeys
>
>    Supports extended keys.
>
> （拙訳）
> terminal-features[] string
> 
> terminfo(5) から読み込まれたターミナルタイプに対して、ターミナル機能を設定します。tmux には、名前が付けられた一連のターミナル機能があります。それぞれが、使用中の terminfo(5) エントリに対して適切な変更を適用します。
> tmux は、いくつかの一般的なターミナルの機能を検出できますが、このオプションを使用すると、ターミナルがサポートするものの tmux が検出できない機能を tmux に簡単に通知できます。
> terminal-overrides オプションを使用すると、個々の terminfo(5) 機能を設定できます。一方、terminal-features は、標準的な方法でサポートされているものの、terminfo(5) によって報告されない機能のカテゴリを対象としています。
> この設定を行う際は、端末が実際にサポートしている機能のみを使用するように注意してください。`
> 
> これは配列オプションで、各エントリは : で区切られた文字列で構成され、ターミナルタイプのパターン（glob(7) パターンでマッチング）の後にターミナル機能のリストが続きます。
> 
> extkeys
>
>   拡張キーをサポートしている


#### set -s extended-keys-format csi-u

このオプションは、拡張キーの転送フォーマットを CSI-u 形式に指定するための設定です。このオプションの man ページでの説明は以下のとおりです。

> extended-keys-format [csi-u | xterm]
> 
> Selects one of the two possible formats for reporting modified keys to applications.
> This is the equivalent of the formatOtherKeys xterm(1) resource.
> For example, C-S-a will be reported as ‘^[[27;6;65~’ when set to xterm, and as ‘^[[65;6u’ when set to csi-u.
>
> （拙訳）
> extended-keys-format [csi-u | xterm]
>
> 装飾されたキーをアプリケーションにレポートするために使える2つのフォーマットのうち、1つを選択します。
> これは、xterm(1) リソースの formatOtherKeys と同等のものです。
> 例えば、C-S-a は、xterm をセットした場合は ‘^[[27;6;65~’ として、csi-u をセットした場合は ‘^[[65;6u’ としてレポートされます。

### Neovim の設定

Neovim が CSI-u をサポートしたのは 0.8 以降なので、これ以降の Neovim を使っていて、かつ、CSI-u シーケンスが届いていれば冒頭に示した設定で `<C-S-w>` のキーバインドが機能します。

```lua
-- コード再掲
vim.keymap.set({ 'n', 't' }, "<C-S-w>", function()
  local result, _ = pcall(require, 'chowcho')
  if not result then
    vim.api.nvim_command('wincmd w')
    return
  else
    local wins = 0
    for i = 1, vim.fn.winnr('$') do
      local win_id = vim.fn.win_getid(i)
      local conf = vim.api.nvim_win_get_config(win_id)
      if conf.focusable then
        wins = wins + 1
        if wins > 2 then
          chowcho.run()
          return
        end
      end
    end
    vim.api.nvim_command('wincmd p')
  end
end)
```

## まとめ

今回の解決策のポイントをまとめると次のとおりです。

- Rio terminal は、`Ctrl-Shift-W` を CSI-u 形式でネイティブ送出できないため、`esc` パラメータでエスケープシーケンスをハードコードする
- tmux は `extended-keys always` で強制的に拡張キーを受け付けるようにする
- tmux の `terminal-features '*:extkeys'` でワイルドカード指定することで、`$TERM` の値によらず確実に拡張キーを有効化する

この方法は Rio に限らず、CSI-u 形式での送出が不完全な他のターミナルにも応用できると思います。また、`Ctrl-Shift-数字` など他のキーの組み合わせで同様の問題が起きた場合も、文字コードと modifier 値を変えて `esc` パラメータに指定することで対応できます。

CSI-u の文字コードは対象文字の ASCII コード、modifier 値は Shift=2、Alt=4、Ctrl=5、Ctrl-Shift=6 の組み合わせで計算します（1 を加えた値）。たとえば `Ctrl-Shift-T` なら `\u001b[116;6u` になります。

## 補足（現在のターミナルアプリで `Ctrl-Shift-A` と `Ctrl-A` が区別されない理由）

上記の解決策は、自力でウェブ検索したり AI に尋ねたりして辿り着いたものですが、調査の過程で、現在のターミナルアプリで `Ctrl-Shift-A` と `Ctrl-A` が区別されない理由が分かってきましたので、調べたことを Claude に整理してもらったものを参考までに掲載します。

---

（以下は Claude にまとめてもらった文章です）

現代のターミナルアプリで `Ctrl-Shift-A` と `Ctrl-A` が同じ入力として扱われることがあるのは、物理端末時代から続く「キーイベントではなく文字コードを送る」という設計を引き継いでいるためです。

GUIアプリは、OSから「Aキーが押された」「Ctrlが押されている」「Shiftも押されている」というキーイベントを受け取れます。しかし、ターミナルアプリがシェルや Vim/Neovim などに渡す入力は、多くの場合、そうした生のキーイベントではなく、**端末が生成した文字コードまたはエスケープシーケンス**です。

歴史的な物理端末であるVT100でも、ShiftキーやCtrlキーは単体のキーコードとしてホストへ送られるものではありませんでした。VT100 User Guideには、ShiftやCtrlはそれ自体ではコードを送信せず、他のキーが送信するコードを変更するキーだと説明されています。また、Ctrlキーは他のキーと組み合わせて制御コードを生成すると説明されています。([blog.schmorp.de][1])

つまり、VT100的なモデルでは、

```text
キー入力 + 修飾キー
  ↓
端末側で文字コードに変換
  ↓
ホストへ送信
```

という流れになります。ホスト側には「Ctrlが押されていた」「Shiftが押されていた」という独立した情報ではなく、**変換後のバイト列**だけが届きます。

`Ctrl-A` と `Ctrl-Shift-A` が同じになりやすい理由は、ASCIIのコード配置にもあります。ASCIIでは、

```text
A = 0x41
a = 0x61
Ctrl-A = 0x01
```

です。典型的なCtrl変換は、「大文字の文字コードから `0x40` を引く」または「ASCIIコードを `0x1F` とANDする」と説明できます。この方式では、`A` と `a` の違い、つまりShiftによる大文字・小文字の違いが消えてしまいます。制御文字の説明でも、Controlキーは文字キーと組み合わせて `0x00`〜`0x1F` の制御コードを生成するものとして説明されています。([Wikipedia][2])

そのため、端末アプリが従来互換の入力変換を行うと、概念的には次のようになります。

```text
Ctrl-a       → 0x01
Ctrl-A       → 0x01
Ctrl-Shift-a → 0x01
```

アプリ側、たとえばシェルやVim/Neovimから見ると、どれも同じ `^A` に見えます。したがって、端末から同じバイト列しか届いていない状況では、アプリ側で `<C-a>` と `<C-S-a>` を別々に割り当てることはできません。

ここで重要なのは、**現代のOSやターミナルアプリが技術的にShift状態を取得できないわけではない**という点です。現代のGUI環境では、ターミナルアプリ自体は通常 `Ctrl` や `Shift` の状態を知ることができます。しかし、それをそのままTUIアプリへ渡す標準的な経路が、歴史的には「キーイベント」ではなく「文字コード列」だったため、互換性を優先すると `Ctrl-Shift-A` と `Ctrl-A` は同じ `0x01` に畳み込まれます。

この制限を回避するため、近年は拡張キーボードプロトコルが使われるようになっています。代表例が **kitty keyboard protocol** です。kittyの仕様では、従来の端末入力との後方互換性を保ちつつ、アプリケーションが明示的に有効化することで、修飾キーなどをより詳しく報告できる仕組みだと説明されています。([Kovid Goyal's Projects][3])

また、iTerm2には **CSI u** という拡張方式があります。iTerm2のドキュメントでは、CSI uは標準的なUnix端末入力より強力なキーストローク報告方式だが、現在はkitty key reporting protocolの利用が推奨されると説明されています。([iTerm2][4])

したがって、現代の状況は次のように整理できます。

```text
従来互換モード:
  Ctrl-A と Ctrl-Shift-A はどちらも 0x01 になりやすい
  → アプリ側では区別できない

拡張キーボードプロトコル対応時:
  Ctrl-A と Ctrl-Shift-A を別の入力として報告できる場合がある
  → ただし、ターミナル・tmux・アプリ側の対応が必要
```

結論として、現在のターミナルアプリで `Ctrl-Shift-A` と `Ctrl-A` が区別されないのは、**VT100のような物理端末に由来する「修飾キーを最終的な文字コードへ畳み込んで送る」モデルと、ASCIIにおける制御文字の設計を引き継いでいるため**です。

一方で、kitty keyboard protocol や CSI u のような拡張を使えば、この歴史的制約を回避できる場合があります。ただし、そのためにはターミナルエミュレータだけでなく、tmux や Neovim など、入力を受け取る側もそのプロトコルに対応している必要があります。

[1]: https://blog.schmorp.de/data/vt102/EK-VT100-UG-002_VT100_User_Guide_Jan79.pdf
[2]: https://en.wikipedia.org/wiki/Control_character
[3]: https://sw.kovidgoyal.net/kitty/keyboard-protocol
[4]: https://iterm2.com/documentation-csiu.html
