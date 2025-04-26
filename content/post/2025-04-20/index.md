---
# type: docs 
date: '2025-04-20T14:51:17+09:00'
draft: false
title: Windows on Arm の WSL2 で NixOS をインストールする方法
featured: false
comment: true
toc: true
tags: [WSL, NixOS]
archives: 2025/04
---

## 前置き

自宅のデスクトップPCの WSL2 に NixOS をインストールして使っていますが、最近ノートPCを購入しましたので、そちらの WSL2 にも NixOS をインストールしたいと思いました。しかし、新しいノートPC は Snapdragon X Elite CPU 搭載の Windows on ARM PC なので、Intel Inside PC と同じ手順ではインストールできませんでした。

Nix コミュニティが運営している Wiki の [NixOS on ARM - NixOS Wiki](https://nixos.wiki/wiki/NixOS_on_ARM) に ARM アーキテクチャへのインストール方法が掲載されていますが、Windows on ARM へのインストール方法はありませんでした（Raspberry Pi などのシングルボードコンピュータへのインストール方法がメインです）。

とはいえ、色々調べたり相談したりした結果、自宅のデスクトップPCとノートPCで「同じ設定ファイル・同じコマンド」を使ってインストールと設定ができるようになりましたので、備忘録としてその方法をまとめます。

なお、本記事の内容は 2025年4月時点で調べた結果に基づいています。

## インストール用イメージのビルド

WSL2 にインストールする NixOS は Nix コミュニティがメンテナンスしている [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) としますが、GitHub で配布されているバージョンは Intel X86_64 版です。幸い、GitHub の Issues に [Unable to run on Windows ARM with Snapdragon X Elite](https://github.com/nix-community/NixOS-WSL/issues/534) というそのものズバリの Issue があり、そこに解決策も提示されていました。

解決策を一言で言うと、GitHub で公開されている設定を変更して ARM 対応版をビルドしてインストールするというものです。具体的な手順は次のとおりです。なお、デスクトップPCでのクロスコンパイルは上手くいかなかったため、以下の作業はノートPC で行っています。

1. ノートPC で WSL2 を有効化します。
2. Microsoft Store から Ubuntu をインストールします（ビルド作業で Nix が必要なものの、Nix は Windows 非対応なので、WSL2 にインストールした Ubuntu に Nix をインストールします。）。
3. インストールした Ubuntu を起動します。
4. Nix の[公式サイト](https://nixos.org/download/) の説明に従い、シングルユーザーモードで Nix をインストールするために `sh <(curl -L https://nixos.org/nix/install) --no-daemon` を実行します。
5. インストールが完了すると、環境変数をセットするため、再ログインするか `. /home/s-show/.nix-profile/etc/profile.d/nix.sh` を実行するよう指示されるので、どちらかを選択します。
6. `git clone https://github.com/nix-community/NixOS-WSL.git` で NixOS-WSL のリポジトリを clone します。
7. `cd NixOS-WSL` で clone したディレクトリに移動します。
8. `flake.nix` を以下のとおり編集します。

```diff
nixosConfigurations = {
  default = lib.nixosSystem {
-    system = "x86_64-linux";
+    system = "aarch64-linux";
  modules = [
    self.nixosModules.default
    ({ config, lib, pkgs, ... }: {
```
9. `nix-build -A nixosConfigurations.default.config.system.build.tarballBuilder` を実行してビルド用のファイルを作成します。
10. `sudo ./result/bin/nixos-wsl-tarball-builder` を実行して tarball を作成します。
11. 作成した tarball を`cp nixos.wsl /mnt/~~~` でノートPCの任意の場所にコピーします。
12. PowerShell を起動して `wsl --install --from-file nixos.wsl` を実行し、先程作成した tarball から NixOS をインストールします。
13. 成功すれば「ディストリビューションが正常にインストールされました。'wsl.exe -d NixOS' を使用して起動できます」と表示されます。

## 設定


### 設定の基本的なスタンスと概要

これで WSL2 に NixOS をインストールできましたので、次は OS を設定します。ただし、前置きに書きましたとおり、私は「同じ設定ファイル・同じコマンド」で自宅のデスクトップPCとノートPC を管理したかったので、この要求を満すのにだいぶ苦労しました。Slack の [vim-jp](https://vim-jp.org/docs/chat.html) の #tech-nix チャンネルで相談を重ねて何とかなりましたので、アドバイスしていただいた方々には感謝申し上げます。

2つのPCで変える必要がある設定は `flake.nix` の `inputs.nixpkgs.lib.nixosSystem.system` で、この設定をアーキテクチャに応じて `intel_x86_64-linux` または `aarch64-linux` にします。アーキテクチャに応じて設定を変える方法が必要となりますが、最初は以下のようにプロファイルを2つ用意していました。

```nix
nixosConfigurations = {
  myNixOS_x86_64-linux = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./configuration.nix
    ];
  };
  myNixOS_aarch64-linux = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./configuration.nix
    ];
  };
};
```

そして、設定を変更する時は、アーキテクチャに応じてコマンドの引数を `.#myNixOS_x86_64-linux` または `.#myNixOS_aarch64-linux` と変えていました。ところが、この方法を Slack で報告したら `nixosConfiguration.hostname` とすれば Nix がホスト名に応じて読み込む設定を自動的に切り替えてくれると教えてもらいましたので、`flake.nix` を以下のとおり変更しました。

```nix
nixosConfigurations = {
  desktop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./configuration.nix
    ];
  };
  zenbook = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./configuration.nix
    ];
  };
};
```

この方法を使うにはデスクトップPCとノートPCでホスト名を変える必要がありますが、`/etc/hostname` を編集したり `sudo hostnamectl set-hostname {hostname}` でホスト名を変更したりする方法では再インストールの時に絶対忘れてしまうと思ったので、ホスト名の変更も Nix に任せることにしました。具体的には、`configuration.nix` を以下のとおり設定してアーキテクチャに応じてホスト名を設定するようにしました。

```nix
{ config, lib, pkgs, ... }:
  let
    hostname = if pkgs.system == "x86_64-linux" then
      "desktop"
    else if pkgs.system == "aarch64-linux" then
      "zenbook"
    else
      "generic";
  in
  {
    networking.hostName = hostname;
```

ここまでの設定により、デスクトップPCとノートPCで「同じ設定ファイル・同じコマンド」で設定を変更できるようになりました。なお、この方法だと `pkgs.system` の値が `x86_64-linux` になるPCが2つ以上になると条件分岐ができなくなりますが、そのときは別の方法を考えることにしています。

### 具体的な設定の手順

設定の基本的なスタンスなどは上記で説明しましたので、ここから具体的な手順を紹介します。

1. まず Powershell で `wsl -d NixOS` を実行して NixOS にログインします。`-u` オプションでユーザー名を指定しない場合のユーザー名は `nixos` になります。
1. `sudo nix-channel --update` を実行してチャンネルをアップデートします。
1. `nix-shell -p git` で一時的に Git を使えるようにしてから、`git clone https://github.com/s-show/dotfiles_nixos ` で設定ファイルを clone します。
1. `mv dotfiles_nixos .dotfiles` でディレクトリ名を変更します。
1. `sudo nixos-rebuild switch -I nixos-config=/home/nixos/.dotfiles/configuration.nix` を実行して最初のリビルドを実行します。
1. Neovim をシステム全体にインストールする設定にしているので、`nvim --version` を実行してリビルドが成功したか確認します。成功していれば Neovim のバージョンが表示されます。
1. `id s-show` を実行して普段使いのユーザーである `s-show` が作成されているか確認します。
1. NixOS を再起動するため `exit` でログアウトします。
1. PowerShell で `wsl --shutdown NixOS` を実行して NixOS を終了し、それから `wsl -d NixOS` を実行して NixOS に再ログインします。
1. `hostname` を実行してホスト名が想定通りになっているか確認します（再起動前に `hostname` を実行してもホスト名は変更されていません）。
1. `exit` で NixOS をログアウトしてから `wsl -d NixOS -u s-show` でユーザー `s-show` で NixOS にログインします。ログインしたら ZSH の設定ダイアログが表示されるので、`q` をタイプして設定をスキップします（ZSH の設定は Nix で行うため）。
1. `git clone https://github.com/s-show/dotfiles_nixos` で設定ファイルを再度ダウンロードします（`nixos` ユーザーで clone した設定ファイルは `/home/nixos/` に保存されているため）。
1. `mv dotfiles_nixos .dotfiles` でディレクトリ名を変更します。
1. `nix run nixpkgs#home-manager -- switch --flake .` を実行して home-manager を導入するとともに、`home.nix` 設定を反映させます。
1. `home.nix` の `home.packages = with pkgs; []` に列挙しているアプリを実行します。上手く設定されていればアプリが使えるはずです。

これで NixOS の設定は完了です。

## 後書き

2つのPCで「同じ設定ファイル・同じコマンド」で NixOS をインストールして設定できるようにしましたが、一度設定ファイルを作ってしまえば簡単に再現できるようになるという Nix の強みをより強く実感できるようになりました。

この記事を書くため、WSL2 に追加で NixOS をインストール（`wsl --install --name nixos2 --from-file .\Downloads\nixos.wsl`）して上記と同じ手順で作業したところ、問題なく NixOS を設定できましたし、所要時間も30分程度でした。

引き続き NixOS で遊んでみようと思います。

追伸

記事執筆時点の設定ファイルは以下のリンクから確認できます。

[s-show/dotfiles_nixos](https://github.com/s-show/dotfiles_nixos/tree/78ed772866197e53f5a28f0e05d4753a9f4b4597)
