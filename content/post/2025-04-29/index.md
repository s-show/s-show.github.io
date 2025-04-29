---
# type: docs 
date: '2025-04-29T14:00:00+09:00'
draft: false
title: NixOS で .local/bin ディレクトリを生成して自作スクリプトを保存する方法
featured: false
comment: true
toc: true
tags: [NixOS, home-manager]
archives: 2025/04
---

## 前置き

NixOS の home-manager でユーザー環境を管理していますが、設定を編集する都度 `cd .dotfiles && home-manager switch flake . && cd` と長いコマンドを実行する必要があるのが少し面倒でした。

そうしたとき、[Taskfile（taskコマンド）のfish補完定義を改善してグローバルタスクに対応した | Atusy's blog](https://blog.atusy.net/2025/04/23/cloud-run-with-iam/) という記事を読んで、専用のコマンドが簡単に作れることが分かりましたので、これを NixOS の機能を活用しながら応用することにしました。

設定内容は大したものではないですが、NixOS の Tips になるかと思いましたので、備忘録代わりにまとめます。

## 環境

OS: NixOS on WSL2 (Windows on ARM)

```bash
> nix-shell -p nix-info --run "nix-info -m"
 - system: `"aarch64-linux"`
 - host os: `Linux 5.15.167.4-microsoft-standard-WSL2, NixOS, 24.11 (Vicuna), 24.11.717196.9684b53175fc`
 - multi-user?: `yes`
 - sandbox: `yes`
 - version: `nix-env (Nix) 2.24.14`
 - channels(root): `"nixos-24.11, nixos-wsl"`
 - nixpkgs: `/nix/var/nix/profiles/per-user/root/channels/nixos`

> home-manager --version
25.05-pre
```

## シェルスクリプトの作成

NixOS でシェルスクリプトを作成する場合、1つ注意点があります。NixOS は独自のファイル構造を採用して [Filesystem Hierarchy Standard - Wikipedia](https://ja.wikipedia.org/wiki/Filesystem_Hierarchy_Standard) に準拠していないため、冒頭の shebang を `#!/bin/bash` と書いても実行時にエラーになります[^1]。

[^1]: bash の保存場所が `/run/current-system/sw/bin/bash` になっているためです。

ではどうするかと言いますと、shebang を `#!/usr/bin/env bash` とします。これにより、`env` コマンド経由で bash が起動しますので、シェルスクリプトのコードが無事に実行されます[^2]。

[^2]: `env bash` を実行すると bash が起動します。

実際に作成したシェルスクリプト（`~/.dotfiles/home-update`）は次のとおりです。

```bash
#!/usr/bin/env bash

cd ~/.dotfiles
git add .
home-manager switch --flake .
cd ~/
```

スクリプトを作成したら、`chmod +x .dotfiles/home-update` コマンドで実行権限を付与します。

## 設定内容

ここから `.dotfiles/home-update` スクリプトのシンボリックリンクを `.local/bin` に作成して `home-update` コマンドで実行できるよう設定します。

まず、`configuration.nix` に `environment.localBinInPath = true` を追加して `.local/bin` がパスに追加されるようにします。

それから、`home.nix` に以下のコードを追加してシンボリックリンクを作成しています。

```nix
home.file.".local/bin/home-update" = {
  source = config.lib.file.mkOutOfStoreSymlink "${builtins.toString config.home.homeDirectory}/.dotfiles/home-update";
};
```

- `home.file.".local/bin/home-udate" = {}` は、シンボリックリンクとして作成する `.local/bin/home-update` の各種設定を宣言する部分です。シンボリックリンクの場所の指定はホームディレクトリからの相対参照にします。
- `source = config.lib.file.mkOutOfStoreSymlink "${builtins.toString config.home.homeDirectory}/.dotfiles/home-update";` の内容は次のとおりです。
    - `lib.file.mkOutOfStoreSymlink` 関数を使うことで、Nix ストア（`/nix/stor`）以外の場所にシンボリックリンクを作成できるようにします。
    - `lib.file.mkOutOfStoreSymlink` の引数としてリンク元のパスを渡しますが、パスの直打ちを避けたかったので、`${builtins.toString config.home.homeDirectory}` でホームディレクトリのパスを文字列として取得し、そこに `.dotfiles/home-update` を繋げることでリンク元のフルパスを作成して関数に渡しています。
    - 上記の設定を `source` に渡すことで、`.local/bin/home-manager` のリンク元を `~/.dotfiles/home-manager` に設定しています。

ここまで設定したら `cd .dotfiles &&  git add . && home-manager switch --flake . && cd` コマンドを実行して設定を反映させます。すると、コマンド実行前に `.local/bin` ディレクトリが作成されていなかったとしても、ディレクトリが自動的に作成されてシンボリックリンクが配置されます。

これで `home-update` コマンドを実行できるようになりました。

## 参考情報

- [`environment.localBinInPath` の説明](https://search.nixos.org/options?channel=24.11&show=environment.localBinInPath&from=0&size=50&sort=relevance&type=packages&query=localBin)
- [`home.file` の説明](https://nix-community.github.io/home-manager/options.xhtml#opt-home.file)
- [`home.file.source` の説明](https://nix-community.github.io/home-manager/options.xhtml#opt-home.file._name_.source)
- [`lib.file.mkOutOfStoreSymlink` 関数の定義](https://github.com/nix-community/home-manager/blob/c803a38927b9b3b15dc83aecae27af3172be5ee2/modules/files.nix#L76-L90)
- [How do you run a bash script? - Help - NixOS Discourse](https://discourse.nixos.org/t/how-do-you-run-a-bash-script/10141)

