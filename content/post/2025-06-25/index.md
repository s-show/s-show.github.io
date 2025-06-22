---
title: Nix を使って複数バージョンの Neovim をインストールする方法
date: 2025-06-25T00:00:00+09:00 # Date of post creation.
featured: false
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: true
usePageBundles: false # Set to true to group assets like images in the same folder as this post.
featureImage: '/images/2025-06-25/eyecatch.png' # Sets featured image on blog post.
featureImageAlt: 'eyecatch image' # Alternative text for featured image.
figurePositionShow: true # Override global value for showing the figure label.
tags: [NixOS, Flakes, home-manager, neovim]
archives: 2025/06
comment: true # Disable comment if false.
---

## 前置き

Neovim のプラグインで古い Neovim での挙動を確認したいものがありましたので、NixOS で複数バージョンの Neovim をインストールする方法を調査しました。

調査の結果、無事に「古いバージョン・安定版・Nightly版」の3つをインストールすることができましたので、その方法を備忘録としてまとめます。

## 環境

本記事を執筆した 2025年6月23日時点のものです。

### OS

NixOS on WSL2

```zsh
> uname -a
Linux desktop 5.15.167.4-microsoft-standard-WSL2 #1 SMP Tue Nov 5 00:21:55 UTC 2024 x86_64 GNU/Linux
```

### Nix

```zsh
> nix-shell -p nix-info --run "nix-info -m"
 - host os: `Linux 5.15.167.4-microsoft-standard-WSL2, NixOS, 25.11 (Xantusia), 25.11.20250529.3866ad9`
 - multi-user?: `yes`
 - sandbox: `yes`
 - version: `nix-env (Nix) 2.28.3`
 - channels(root): `"nixos-24.11, nixos-wsl"`
 - nixpkgs: `/nix/store/s7ga48spdagfm0j1rd740q52ih159g51-source``

### home-manager

```zsh
> home-manager --version
25.05-pre
```

home-manager は NixOS のモジュールとして導入しています。

### シェル

```zsh
> zsh --version
zsh 5.9 (aarch64-unknown-linux-gnu)
```

## 実際のコード

今回インストールした Neovim は以下の3つで、`nvim` で Nightly 版を、`nvim-stable` で 0.11.1を、`nvim-0104` で 0.10.4を起動するように設定しています。

- version 0.10.4 (テストのためのバージョン)
- version 0.11.1 (Nix の 25.05・Unstable 版のバージョン。以下「安定版」とする。)
- version 0.12.0-nightly+b28bbee (Nightly 版)

アプリは home-manager で管理していますので、`home.nix` に必要な設定を書いたら `git add home.nix` して `sudo nixos-rebuild switch --flake . --impure` を実行してインストールするのですが、Nightly 版を使うために `flake.nix` にも設定を書いています。 

実際のコードを見た方が話が早いと思うので、今回の記事に関係する部分を抜粋します。コードの解説は次節の「コードの解説」で行います

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };
  outputs = inputs: {
    nixosConfigurations = {
      desktop = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          # Home ManagerをNixOSモジュールとして統合
          inputs.home-manager.nixosModules.home-manager
          {
            # nixpkgsにoverlayを適用
            nixpkgs.overlays = [
              inputs.neovim-nightly-overlay.overlays.default
            ];
            # Home Manager設定
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.s-show = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
  };
}
```

```nix
# home.nix
{ config, pkgs, lib, inputs, ... }:
let
  oldNixpkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/c5dd43934613ae0f8ff37c59f61c507c2e8f980d.tar.gz";
  }) {};
 
  commonWrapperArgs = {
    wrapRc = false;
    wrapperArgs = [
      "--suffix"
      "LD_LIBRARY_PATH"
      ":"
      "${pkgs.stdenv.cc.cc.lib}/lib"
    ];
  };

  neovim-sources = {
    v0104 = oldNixpkgs.neovim-unwrapped;
    stable = inputs.nixpkgs.legacyPackages.${pkgs.system}.neovim-unwrapped;
    nightly = pkgs.neovim-unwrapped;
  };
 
  neovim_0104 = pkgs.wrapNeovimUnstable neovim-sources.v0104 commonWrapperArgs;
  neovim-stable = pkgs.wrapNeovimUnstable neovim-sources.stable commonWrapperArgs;
  neovim-nightly = pkgs.wrapNeovimUnstable neovim-sources.nightly commonWrapperArgs;

  nvim-stable-wrapper = pkgs.writeShellScriptBin "nvim-stable" ''
    exec ${neovim-stable}/bin/nvim "$@"
  '';
  nvim-0104-wrapper = pkgs.writeShellScriptBin "nvim-0104" ''
    exec ${neovim_0104}/bin/nvim "$@"
  '';
in
{
  home = {
    packages = with pkgs; [
      neovim-nightly
      nvim-stable-wrapper
      nvim-0104-wrapper
    ];
  };

  programs.neovim.plugins = [
    pkgs.vimPlugins.nvim-treesitter.withAllGrammars
  ];
}
```

## コードの解説

ここからコードの解説に入ります。まずコードを再掲し、その下に解説を書きます。

```Nix
# home.nix
oldNixpkgs = import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/c5dd43934613ae0f8ff37c59f61c507c2e8f980d.tar.gz";
}) {};
```
このコードは、バージョン 0.10.4 の Neovim が含まれている Nixpkgs を取得するためのコードです。

`flake.nix` で指定している Nixpkgs は "unstable" で、現在の "unstable" の Neovim は 0.11.2 なので、0.10.4 をインストールするには古い Nixpkgs が必要となります。そのため、`builtins.fetchTarball` 関数で 0.10.4 が含まれている古い Nixpkgs を取得しています。なお、URL にコミットハッシュを含めていますが、このハッシュは [Nix Package Versions](https://lazamar.co.uk/nix-versions/) で調べたものを指定しています。

```nix
# home.nix
commonWrapperArgs = {
  wrapRc = false;
  wrapperArgs = [
    "--suffix"
    "LD_LIBRARY_PATH"
    ":"
    "${pkgs.stdenv.cc.cc.lib}/lib"
  ];
};
```

このコードは、Neovim をカスタマイズしてインストールする際のオプションを変数として指定しているものです。今回は3つのバージョンの Neovim をインストールしますが、3つとも同じオプションでセットアップしますので、同じコードを複数回書くのを防ぐために変数にしています。

```nix
# home.nix
neovim-sources = {
  v0104 = oldNixpkgs.neovim-unwrapped;
  stable = inputs.nixpkgs.legacyPackages.${pkgs.system}.neovim-unwrapped;
  nightly = pkgs.neovim-unwrapped;
};
```

このコードは、今回インストールする3つのバージョンをどのパッケージから取得するのかを指定するものです。

バージョン0.10.4は、1つ前のコードで取得した古いパッケージから取得しています。

安定版は、`flake.nix` で指定している unstable 版のものを使うため、`inputs.nixpkgs.legacyPackages.${pkgs.system}.neovim-unwrapped` としています。`flake.nix` で `home-manager.extraSpecialArgs = { inherit inputs; };` としていますので、`home.nix` で `inputs.nixpkgs` とすれば `flake.nix` で指定しているものが使えます。

なお、現在の unstable 版の Nixpkgs の Neovim は 0.11.2 ですが、私の unstable 版はそこまで追い付いていないので、ちょっとだけバージョンが違います。[^1]

Nightly 版は、`flake.nix` の `nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlays.default ];` により `pkgs` が overlay されたものになっていますので、`pkgs.neovim-unwrapped;` とすれば OK です。


```nix
# home.nix
neovim_0104 = pkgs.wrapNeovimUnstable neovim-sources.v0104 commonWrapperArgs;
neovim-stable = pkgs.wrapNeovimUnstable neovim-sources.stable commonWrapperArgs;
neovim-nightly = pkgs.wrapNeovimUnstable neovim-sources.nightly commonWrapperArgs;
```

このコードは、3つのバージョンそれぞれについて、`pkgs.wrapNeovimUnstable` 関数を使ってカスタマイズしているものです。

私の場合、`LD_LIBRARY_PATH` を指定しないと動かないプラグインがありますので、`commonWrapperArgs` 変数を引数に渡して設定しています。

```nix
# home.nix
nvim-stable-wrapper = pkgs.writeShellScriptBin "nvim-stable" ''
  exec ${neovim-stable}/bin/nvim "$@"
'';
nvim-0104-wrapper = pkgs.writeShellScriptBin "nvim-0104" ''
  exec ${neovim_0104}/bin/nvim "$@"
'';
```

このコードは、v0.10.4 を `nvim-0104` コマンドで、stable 版を `nvim-stable` コマンドでそれぞれ起動できるようにするためのものです。`pkgs.writeShellScriptBin` 関数は、1つ目の引数にコマンド名を指定し、2つ目の引数にそのコマンドを実行したときの処理を記述します。なお、引数にある `"$@"` は、`nvim-stable` や `nvim-0104` コマンドに渡された引数をそのまま `exec ~~` に渡すという指定です。

なお、Nightly 版の Neovim を起動するためのコマンドは指定していませんので、Nightly 版は通常のコマンドである `nvim` で起動できます。

```nix
# home.nix
home = {
  packages = with pkgs; [
    neovim-nightly
    nvim-stable-wrapper
    nvim-0104-wrapper
  ];
};
```

このコードは、home-manager でインストールするアプリとして、これまで設定してきた3つのバージョンの Neovim を指定するものです。

アプリの名前として指定している値のうち、Nightly 版は2つ上のコードブロックの `neovim-nightly = pkgs.wrapNeovimUnstable` を使っています。Stable 版は、1つ上のコードブロックの `nvim-stable-wrapper = pkgs.writeShellScriptBin` を、v0.10.4 は同じコードブロックの `nvim-0104-wrapper = writeShellScriptBin` を使います。

これで設定は完了ですので、`git add .` で `flake.nix` と `home.nix` をステージングしたら `sudo nixos-rebuild switch --flake . --impure --show-trace` を実行します。上手くいけば3つのバージョンの Neovim がインストールされるはずです。

## 補足

今回の記事執筆にあたり調べたことのメモです。

### neovim-unwrapped とは

今回の設定で `neovim-unwrapped` というパッケージを使用していますが、これは `neovim` と対になるパッケージで、Nix の公式リファレンスにある [Nixpkgs Reference Manual](https://nixos.org/manual/nixpkgs/unstable/#neovim-custom-configuration) では以下のとおり説明されています。

> Install neovim-unwrapped to get a barebone neovim to configure imperatively. This is the closest to what you encounter on other distributions.
> neovim is a wrapper around neovim with some extra configuration to for instance set the various language providers like python. The wrapper can be further configured to include your favorite plugins and configurations for a reproducible neovim across machines. See the next section for more details.
>
> （拙訳）
> neovim-unwarpped をインストールすると、命令的に設定できるベアボーンの Neovim を入手できます。これは、他のディストリビューションで遭遇するものに最も近いものです。
> neovim は、neovim-unwrapped にラップしたもので、python のような複数の言語プロバイダーを設定するための追加設定が含まれています。このラッパーは、お気に入りのプラグインや設定を複数のマシンの間で再現可能にするためにさらにカスタマイズすることができます。詳細は次のセクションを見てください。

実際、nixpkgs のリポジトリにある [Neovim の Nix 式](https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/applications/editors/neovim/wrapper.nix)を見ますと、neovim-unwarpped を元に設定を追加する形になっています。

そして、この neovim-unwrapped に設定を追加する際に使うのが `wrapNeovimUnstable` 関数です。

### wrapNeovimUnstable とは

`wrapNeovimUnstable` 関数は、neovim-unwrapped に設定を追加する際に使う関数で、Nix の公式リファレンスにある [Nixpkgs Reference Manual](https://nixos.org/manual/nixpkgs/unstable/#neovim-custom-configuration) では以下のとおり説明されています。

> wrapNeovimUnstable intended to replace the former. It has more features but the interface is not stable yet.
>
> （拙訳）
> wrapNeovimUnstable は、従前の wrapNeovim を置き換えることを意図しているものです。多くの機能がありますが、インターフェースはまだ安定していません。

この関数の引数は複数ありますが、今回は `wrapRc` と `wrapperArgs` の2つを使っています。

`wrapRc` と `wrapperArgs` の説明は以下のとおりです。

> wrapRc: Nix, not being able to write in your $HOME, loads the generated Neovim configuration via the $VIMINIT environment variable, i.e. : export VIMINIT='lua dofile("/nix/store/…-init.lua")'. This has side effects like preventing Neovim from sourcing your init.lua in $XDG_CONFIG_HOME/nvim (see bullet 7 of :help startup in Neovim). Disable it if you want to generate your own wrapper. You can still reuse the generated vimscript init code via neovim.passthru.initRc.
>
> （拙訳）
> wrapRc: Nix は `$HOME` に書き込みができませんので、Nix で生成された Neovim の設定は、環境変数の `$VIMINIT` 経由で読み込みます。例えば、`export VIMINIT='lua dofile("/nix/store/…-init.lua")'` のような形で読み込みます。これには Neovim が `$XDG_CONFIG_HOME/nvim` にある `init.lua` を読み込むのを妨げるという副作用があります（Neovim のヘルプの startup の 7. を参照）。自分でラッパーを生成する場合、このオプションは無効化してください。無効化しても、`neovim.passthru.initRc` 経由で生成された vimscript の初期化コードを再利用できます。

> wrapperArgs: Extra arguments forwarded to the makeWrapper call.
>
> （拙訳）
> wrapperArgs: `makeWrapper` 関数に渡される追加引数。

### writeShellScriptBin とは

今回の設定で `nvim-stable` コマンドで安定版の Neovim を起動できるようにするために使った関数ですが、Nix の公式リファレンスにある [Nixpkgs Reference Manual](https://nixos.org/manual/nixpkgs/unstable/#trivial-builder-writeShellScriptBin) では以下のとおり説明されています。

> Write a Bash script to a “bin” subdirectory of a directory in the Nix store.
>
> （拙訳）
> Nix ストアのディレクトリの "bin" サブディレクトリに Bash スクリプトを書き込む

この関数は `name` と `text` の2つの引数をとりますが、`name` がコマンド文字列として指定する値、`text` が Bash スクリプトの中身になります。

### nixpkgs.overlays の挙動

`flake.nix` の設定で `nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlays.default ]` というものがあります。これは Nix のオプションの1つで、Nix 公式のオプション検索システムでは以下のとおり説明されています。

> List of overlays to apply to Nixpkgs. This option allows modifying the Nixpkgs package set accessed through the pkgs module argument.
> For details, see the Overlays chapter in the Nixpkgs manual.
>
> （拙訳）
> Nixpkgs に適用する overlay のリスト。このオプションは Nix の モジュールの pkgs 引数を通じてアクセスされる Nixpkgs のパッケージセットを変更することを許可します。
> 詳細は、Nixpkgs のマニュアルの overlay の章を参照してください。

この説明によると、overlay によって変更された Nixpkgs のパッケージセットには `pkgs` 経由でアクセスできることになります。そのため、`home.nix` で `nightly = pkgs.neovim-unwrapped;` とすすることで overlay 後の Nixpkgs に含まれる Neovim（Nightly 版）を取得できます。

また、安定版の Neovim を取得するために `inputs.nixpkgs.legacyPackages.${pkgs.system}.neovim-unwrapped;` としていますが、ここの `inputs.nixpkgs` は `flake.nix` の冒頭の `inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable" }` で定義されたものを `home-manager.extraSpecialArgs = { inherit inputs; };` を経由して `home.nix` で利用しているものです。

ややこしいですが、`inputs.nixpkgs` は "github:NixOS/nixpkgs/nixpkgs-unstable" で指定された Nixpkgs を使うもので、`pkgs` は overlay された後の Nixpkgs を使うものになります。

[^1]: `nix flake update` で `flake.lock` をアップデートしてバージョンアップしようとしたところ、`error: attribute 'teams' missing` というエラーが出てアップデートできていません。
