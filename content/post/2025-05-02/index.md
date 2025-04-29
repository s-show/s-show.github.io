---
# type: docs 
title: NixOS で特定のアプリだけ unstable 版や nightly 版を使う方法
date: '2025-05-02T00:00:00+09:00'
draft: false
featured: false
comment: true
toc: true
tags: [NixOS, home-manager, neovim]
archives: 2025/05
---

## 前置き

私は NixOS で使うアプリを「システム全体で使うもの」と「特定のユーザーだけが使うもの」に分けて管理しており、「システム全体で使うもの」は `configuration.nix` で管理して `nixos-rebuild` コマンドでインストールできるようにしています。

システム全体で使えるようにしているアプリは「Git、ZSH、Neovim」で、私が使っている [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) の nixpkgs のバージョンは 24.11[^1] なので、`nixos-rebuild` でインストールできる Neovim は v0.10 になります[^2]。

[^1]: [nix-community / NixOS-WSL](https://github.com/nix-community/NixOS-WSL) の [flake.nix](https://github.com/nix-community/NixOS-WSL/blob/60b4904a1390ac4c89e93d95f6ed928975e525ed/flake.nix#L5) で `inputs.nixpkgs.url` が `"github:NixOS/nixpkgs/nixos-24.11"` となっています。
[^2]: nixpkgs の各バージョンでどのバージョンのアプリがインストールされるかは [NixOS Search - Packages](https://search.nixos.org/packages) で確認できます。

このたび、Neovim が v0.11 にバージョンアップして Neovim 単体で LSP を設定できるようになったので試そうと思ったのですが、v0.11 を使うには nixpkgs のバージョンを unstable にする必要があります。しかし、ZSH や Git は安定版を使いたかったので、`configuration.nix` の設定を見直して Neovim だけ unstable 版を使えるようにしました。

色々相談したり調べたりして何とか上手くいきましたので、設定方法を備忘録としてメモします。また、ついでに nightly 版をインストールする方法も調べましたので、合わせてメモします。なお、本記事は 2025年4月27日時点の情報です。

## 環境

OS: NixOS on WSL2 (Windows on ARM)

```zsh
> nix-shell -p nix-info --run "nix-info -m"
 - system: `"aarch64-linux"`
 - host os: `Linux 5.15.167.4-microsoft-standard-WSL2, NixOS, 24.11 (Vicuna), 24.11.717196.9684b53175fc`
 - multi-user?: `yes`
 - sandbox: `yes`
 - version: `nix-env (Nix) 2.24.14`
 - channels(root): `"nixos-24.11, nixos-wsl"`
 - nixpkgs: `/nix/var/nix/profiles/per-user/root/channels/nixos`
```

```zsh
> home-manager --version
25.05-pre
```

## unstable 版を使うための設定

設定していくのは `configuration.nix` です。

まず、Nix の組込み関数の [fetchTarball](https://nix.dev/manual/nix/2.24/language/builtins#builtins-fetchTarball) で unstable 版のパッケージ情報が格納された `https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz` ファイルをダウンロードして展開し、パスを `unstable-tarball` 変数に代入します。

そして、組込み関数の [import](https://nix.dev/manual/nix/2.24/language/builtins#builtins-import) 関数で `unstable-tarball` 変数のパス情報から Nix 式（パッケージ情報）をインポートします。このとき、`import` の2番目の引数に `config = config.nixpkgs.config` を指定することで、安定版と同じ設定を組み込んでいます。

```nix
# configuration.nix

{ config, lib, pkgs, ... }:
let
  # その他の設定
  unstable-tarball = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  unstable = import unstable-tarball {
    config = config.nixpkgs.config;
  };
in
```

それから、システム全体の環境情報が格納されている `/run/current-system/sw` に表示するアプリを指定する [environment.systemPackages](https://search.nixos.org/options?channel=24.11&show=environment.systemPackages&from=0&size=50&sort=relevance&type=packages&query=environment.system) に unstable 版の Neovim を追加します。`/run/current-system/sw/` に追加することで、全てのユーザーが使えるようになります。

```nix
# configuration.nix

{ config, lib, pkgs, ... }:
let
  # ...
  # その他の設定
  # ...
  unstable-tarball = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  unstable = import unstable-tarball {
    config = config.nixpkgs.config;
  };
in
  # ...
  # その他の設定
  # ...

  programs = {
    neovim = {
      enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    vim
    git
    unstable.neovim
  ];
```

ここまで設定できたら、`sudo nixos-rebuild switch` を実行して設定を反映させます。実行後は `nvim --version` を実行し、v0.11 がインストールされたか確認します。

```bash
> nvim --version
NVIM v0.11.0
Build type: Release
LuaJIT 2.1.1741730670
Run "nvim -V1 -v" for more info
```

無事に v0.11 の Neovim をインストールできました。

## nightly 版を使うための設定

unstable 版の Neovim は v0.11 ですが、Nix のコミュニティが管理している [neovim-nightly-overlay](https://github.com/nix-community/neovim-nightly-overlay) を使うと v0.12 がインストールできます。

インストールするための設定については、上記のリンク先の [with Flakes](https://github.com/nix-community/neovim-nightly-overlay?tab=readme-ov-file#with-flakes) の方法と、[Homebrew管理下のCLIをNixに移してみる Home Manager篇](https://zenn.dev/kawarimidoll/articles/9c44ce8b60726f#nixpkgs%E4%BB%A5%E5%A4%96%E3%81%AEflake%E3%81%8B%E3%82%89%E5%8F%96%E3%82%8A%E8%BE%BC%E3%82%80)  の設定を踏まえて以下のとおり設定しました。

本来なら各設定について詳しく説明すべきなのですが、こちらについては各設定が「なぜそうするのか」という点がまだ理解できなかったので、上手くいった設定を紹介するにとどめています。

```nix
# configuration.nix

let
  # nightly 版のインストールでは不要なのでコメントアウトする
  #unstable-tarball = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  #unstable = import unstable-tarball {
  #  config = config.nixpkgs.config;
  #};
in
{
  # ...
  # その他の設定
  # ...

  programs = {
    # home-manager で管理するのでコメントアウトする
    # neovim = {
    #   enable = true;
    # };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    # unstable 版を使わないのでコメントアウトする
    # unstable.neovim
  ];
```

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # nightly 版を使うために URL を追加する
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  # ...
  # その他の設定
  # ...
```

```nix
# home.nix

{ config, pkgs, inputs, ... }:
{
  home = rec {
    username = "s-show";
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };

  # ...
  # その他の設定
  # ...

  # nightly 版を使うために追加
  nixpkgs = {
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default
    ];
  };

  # インストールするアプリに Neovim を追加
  home.packages = with pkgs; [
    neovim
  ];
```

これで Neovim の nightly 版がインストールできると思います。

```zsh
> nvim --version
NVIM v0.12.0-nightly+7692a62
Build type: Release
LuaJIT 2.1.1741730670
Run "nvim -V1 -v" for more info
```

