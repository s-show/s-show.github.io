---
# type: docs 
date: '2025-04-20T14:51:17+09:00'
draft: false
title: ZSH の設定でつまずいたこと
featured: false
comment: true
toc: true
tags: [ZSH, NixOS]
archives: 2025/04
---

## トラブルの内容

ターミナルの入力で Emacs キーバインドによる移動（`ctrl-a`, `ctrl-e` など）を入力しても、カーソルが移動する代わりに `^E` や `^A` が入力されてしまうという症状に遭遇しました。カーソル移動に加えて `ctrl-p` によるコマンド履歴の呼び出しもできないので、操作に著しい支障が生じていました。

色々調べてこの問題を解決できましたので、原因と対応策を備忘録としてメモします。

## 環境

- OS: NixOS on WSL2

```bash
> nix-shell -p nix-info --run "nix-info -m"
 - system: `"aarch64-linux"`
 - host os: `Linux 5.15.167.4-microsoft-standard-WSL2, NixOS, 24.11 (Vicuna), 24.11.716868.60e405b241ed`
 - multi-user?: `yes`
 - sandbox: `yes`
 - version: `nix-env (Nix) 2.24.14`
 - channels(root): `"nixos-24.11, nixos-wsl"`
 - nixpkgs: `/nix/var/nix/profiles/per-user/root/channels/nixos`
```

- ターミナル: Alacritty || Rio terminal

## 原因

結論から言いますと、`home.nix` の `home.sessionVariables.EDITOR` に `nvim` を指定していることが原因でした。

もう少し説明しますと、ZSH は環境変数の `EDITOR` または `VISUAL` に `vi` という文字列があると、キーバインドを `viins` にしてしまいます。デフォルトエディタを Vim(Neovim) にする人はキーバインドも Vim と同じにするだろうと仮定しているようですが、これは流石に余計なお世話としか言いようのない挙動です。

とはいえ、デフォルトエディタを nano にするのはイヤなので、デフォルトエディタを Neovim にしたままキーバインドだけ Emacs にする必要があります。

なお、キーバインドが勝手に変更されるという点は、ZSH のコマンドラインの編集や補完やキーバインドなどの機能を提供する ZSHZLE のマニュアルに以下のとおり記述されています。

> $ man zshzle
> ... If one of the  VISUAL or  EDITOR environment variables contain the string `vi' when the shell starts up then it will be `viins', oth‐ erwise it will be `emacs'.  bindkey's -e and -v options provide a  convenient  way  to  override  this  default choice.

## 設定

こちらも結論から言いますと、設定ファイルの中に `bindkey -e` を追加すれば OK です。私の場合、NixOS の home-manager を使って ZSH を設定していますので、`home.nix` から呼び出す `zsh.nix` を次のとおり変更しました。なお、デフォルトエディタは `configuration.nix` で設定しています。

```diff
# zsh.nix
initExtra = ''
  ABBR_SET_EXPANSION_CURSOR=1
  ABBR_SET_LINE_CURSOR=1
  compinit
+ bindkey -e
  zstyle ':completion:*:default' menu select=1
  eval "$(direnv hook zsh)"
'';
```

この設定を行ってから `git add . && home-manager switch --flake .` を実行して再ログインすると、キーバインドが Emacs になり、`ctrl-a`, `ctrl-e` を入力するとカーソルが移動するようになります。

## 参考にした情報

- [programs.neovim.defaultEditor=true kills bindkey for autosuggest-accept in zsh](https://discourse.nixos.org/t/programs-neovim-defaulteditor-true-kills-bindkey-for-autosuggest-accept-in-zsh/48844)
- [piyolian: 2022-01](https://piyolian.blogspot.com/2022/01/)
