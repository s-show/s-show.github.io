---
title: "llm-agents.nix で AI エージェントツールを Nix で個別管理する" # Title of the blog post.
date: 2026-05-04T00:00:00+09:00 # Date of post creation.
featured: false
draft: false
comment: true
toc: false
tags: [NixOS, home-manager, AI]
archives: 2026/5
---

## 前置き

home-manager を使って AI エージェントツールを含む各種ツールをインストールしていますが、AI ツールは文字通り日々更新されており、少しアップデートしないだけでバージョンが結構遅れてしまいます。

アップデートするには `nix flake update` を実行すればよいのですが、これだと他のツールまでまとめて更新されてしまいます。全てのツールを頻繁にアップデートすると何かのタイミングで予期しないトラブルに遭遇しそうなので、できれば日々使うツールはある程度バージョンを固定しつつ、AI ツールだけ個別にアップデートしたいところです。

この問題を解決するには Nix の overlay や override を使うしかないのかと思ったところ、そういえば最近 Slack の Vim-jp の tech-nix チャンネルで overlay と override の違いが議論されていたことを思い出しましたので、勉強のため投稿履歴を検索しました。すると、[numtide/llm-agents.nix: Nix packages for AI coding agents and development tools. Automatically updated daily.](https://github.com/numtide/llm-agents.nix) という各種 AI エージェントをひとまとめにインストールできるパッケージを見つけました。

このパッケージを利用すると AI エージェントツールだけを別の flake input として管理できるようなので、導入してみることにしました。そこで、本記事では llm-agents.nix のインストール方法と、インストール時に遭遇したトラブルをまとめます。

## 環境

```bash
> uname -a
Linux desktop 5.15.167.4-microsoft-standard-WSL2 #1 SMP Tue Nov 5 00:21:55 UTC 2024 x86_64 GNU/Linux
```

```bash
> nix-shell -p nix-info --run "nix-info -m"
 - system: `"x86_64-linux"`
 - host os: `Linux 5.15.167.4-microsoft-standard-WSL2, NixOS, 26.05 (Yarara), 26.05.20260328.b63fe7f`
 - multi-user?: `yes`
 - sandbox: `yes`
 - version: `nix-env (Nix) 2.31.3`
 - channels(root): `"nixos-24.11, nixos-wsl"`
 - nixpkgs: `/nix/store/6v4frqfyqmw34z3v0av13z0890w3lmjx-source`
```

## llm-agents.nix のインストール

[公式リファレンス](https://github.com/numtide/llm-agents.nix#using-nix-flakes-recommended)に Flakes を使う場合の設定が掲載されていましたので、これを基に以下のとおり設定しました。

まず、`flake.nix` の `inputs` に `llm-agents` を追加します。

```nix
# flake.nix
{
  inputs = {
    # ...
+   llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    inputs:
    let
      # 各マシンのシステムタイプを定義する辞書
      systems = {
        desktop = "x86_64-linux";
        zenbook = "aarch64-linux";
      };

      # NixOS のシステム構成を作成するヘルパー関数（Home Manager統合版）
      mkNixosSystem =
        machine: system:
        inputs.nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ./configuration.nix
            inputs.sops-nix.nixosModules.sops
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
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (machine: {
          name = machine;
          value = mkNixosSystem machine (systems.${machine});
        }) (builtins.attrNames systems)
      );
    };
}
```

次に、`home.nix` の `packages` に llm-agents.nix 経由でインストールする AI エージェントを追加します。

```nix
# home.nix
{ config, pkgs, lib, inputs, ... }:
let
    #...
in
{
  home = {
    inherit username homeDirectory stateVersion;
    packages = with pkgs; [
      #...
      inputs.llm-agents.packages.${pkgs.system}.codex
      inputs.llm-agents.packages.${pkgs.system}.claude-code
      inputs.llm-agents.packages.${pkgs.system}.gemini-cli
      inputs.llm-agents.packages.${pkgs.system}.opencode
    ];
  };

  programs.home-manager.enable = true;

  home.file = {
    #...
    ".config/opencode/plugins".source = mkDotfileSymlink "home/opencode/plugins";
  };

  imports = [
    #...
    ./home/opencode/opencode.nix
  ];
}
```

## インストール時に遭遇したトラブル

ここまで設定してから `sudo nixos-rebuild switch --flake . --impure --show-trace` を実行したところ、以下のエラーが発生しました。

```
nix log /nix/store/54qyp95z5njrkdmm12jgsb17jkf8njj2-home-manager-path.drv
pkgs.buildEnv error: two given paths contain a conflicting subpath:
  `/nix/store/166lpy4lq63rlizljrjcwlwmyxnqsn0w-opencode-1.14.29/bin/opencode' and
  `/nix/store/yannk9n8nyp45y7agjk57fr211x0zc2c-opencode-1.3.2/bin/opencode'
hint: this may be caused by two different versions of the same package in buildEnv's `paths` parameter
hint: `pkgs.nix-diff` can be used to compare derivations
```

エラーメッセージにバージョン違いの opencode が登場しているので、インストール済みの opencode と今回インストールしようとしている opencode がバッティングしていると予想しました。

そこで、まず opencode 以外のツールはインストールできるか確認するため、以下のとおり opencode に関連するコードをコメントアウトして `sudo nixos-rebuild switch --flake . --impure --show-trace` を実行しました。なお、`opencode.nix` は、opencode の設定ファイルです。

```diff
# home.nix
  home = {
    inherit username homeDirectory stateVersion;
    packages = with pkgs; [
-     inputs.llm-agents.packages.${pkgs.system}.opencode
+     #inputs.llm-agents.packages.${pkgs.system}.opencode
    ];
  };
  imports = [
-   ./home/opencode/opencode.nix
+   #./home/opencode/opencode.nix
  ];
```

これだとエラーが発生しなかったので、次は `opencode.nix` のインポートは外したまま opencode のパッケージだけ追加して実行してみました。

```diff
# home.nix
  home = {
    inherit username homeDirectory stateVersion;
    packages = with pkgs; [
-     #inputs.llm-agents.packages.${pkgs.system}.opencode
+     inputs.llm-agents.packages.${pkgs.system}.opencode
    ];
  };
  imports = [
    #./home/opencode/opencode.nix
  ];
```

これでもエラーは発生しませんでした。そこで仕上げとして `opencode.nix` もインポートするようにしてから実行してみました。

```diff
# home.nix
  imports = [
-   #./home/opencode/opencode.nix
+   ./home/opencode/opencode.nix
  ];
```

ところが、ここで再び同じエラーが発生しました。`opencode.nix` のインポートが原因と判断して home-manager の opencode のオプションを確認したところ、`programs.opencode.package` のデフォルト値が `pkgs.opencode` になっていることが判明しました。

{{< bsimage src="./images/home-manager-opencode-option.png" title="home-manager の opencode オプション" >}}

つまり、`opencode.nix` をインポートすると `pkgs.opencode`（nixpkgs の opencode）と `inputs.llm-agents.packages.${pkgs.system}.opencode`（llm-agents.nix の opencode）の2つがインストールされてしまい、バージョン違いの opencode が競合していたということです。

そこで、`opencode.nix` に `programs.opencode.package` を明示的に指定した上で、`home.nix` から opencode の記述を削除しました。

```diff
# home.nix
  home = {
    inherit username homeDirectory stateVersion;
    packages = with pkgs; [
      #...
      inputs.llm-agents.packages.${pkgs.system}.codex
      inputs.llm-agents.packages.${pkgs.system}.claude-code
      inputs.llm-agents.packages.${pkgs.system}.gemini-cli
-     inputs.llm-agents.packages.${pkgs.system}.opencode
    ];
  };
```

```diff
# opencode.nix
{ pkgs, inputs, ... }:
{
  programs.opencode = {
    enable = true;
+   package = inputs.llm-agents.packages.${pkgs.system}.opencode;
    settings = {
      theme = "everforest";
      model = "moonshotai/kimi-k2.6";
      autoupdate = true;
      tui = {
        scroll_acceleration = {
          enabled = true;
        };
      };
      permission = {
        bash = {
          "rm *" = "deny";
          "git push --force*" = "deny";
          "sudo *" = "deny";
          "dd *" ="deny";
          "mkfs*" = "deny";
          "format*" = "deny";
        };
      };
    };
  };
}
```

これでエラーが発生しなくなり、無事に opencode をインストールできました。

## AI エージェントのアップデート

llm-agents.nix 経由で AI エージェントをインストールできるようになりましたので、`nix flake update llm-agents` を実行すれば AI エージェントだけを選択的にアップデートできるようになりました。

```bash
# アップデート前
> opencode --version
1.14.29

> claude --version
2.1.123 (Claude Code)

> codex --version
codex-cli 0.125.0

> gemini --version
0.40.0
```

```bash
# アップデート後
> opencode --version
1.14.30

> claude --version
2.1.126 (Claude Code)

> codex --version
codex-cli 0.128.0

> gemini --version
0.40.1
```

当初の目的どおり、AI エージェントツールだけをまとめてアップデートできるようになりました。

## まとめ

llm-agents.nix を使うことで、AI エージェントツールを独立した flake input として管理でき、他のパッケージを変えることなく AI エージェントだけを個別にアップデートできるようになりました。

インストール時は home-manager のオプションのデフォルト値によるパッケージの競合というトラブルに遭遇しましたが、`programs.opencode.package` を明示的に指定することで解決できました。

本記事が参考になれば幸いです。

## 参考にしたサイト

- [numtide/llm-agents.nix: Nix packages for AI coding agents and development tools. Automatically updated daily.](https://github.com/numtide/llm-agents.nix)
