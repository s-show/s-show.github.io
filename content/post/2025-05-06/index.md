---
# type: docs 
title: NixOS で API key を暗号化しつつ自動的に環境変数に設定する方法
date: '2025-05-06T00:00:00+09:00'
draft: false
featureImage: '/images/2025-05-06/eyecatch.png' # Sets featured image on blog post.
comment: true
toc: true
tags: [NixOS, home-manager]
archives: 2025/05
codeMaxLines: 10
---

## 前置き

Neovim に AI 機能を追加できるプラグインが複数登場していますので、その1つである [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) を使ってみようと思いました。

ただ、AI 機能を使うには API 呼び出しが必要で、codecompanion.nvim で API を呼び出すには API key を環境変数にセットする必要があります。`export HOGE_API_KEY=****` と入力すれば API key を環境変数にセットできますが、コマンド履歴に API key が残りますし、ログインするたびに実行するのは面倒です。しかし、Nix の設定ファイルに API key を書き込む方法では、誤ってそのファイルを Github にプッシュして漏洩する可能性があります。

そこで対応策を探したところ、Mozilla 財団が暗号化されたファイルを扱うためのエディタを開発しており、それを NixOS に組み込むことで機密情報を安全に管理する方法があることが分かりましたので、導入することにしました。

しかし、実際に使えるようになるまで相当苦労しましたので、再度同じ作業をする羽目になったときに備えて備忘録として手順などをまとめます。

## 環境

### OS

NixOS on WSL2 (Windows on ARM)

### Nix

```zsh
> nix-shell -p nix-info --run "nix-info -m"
 - system: `"aarch64-linux"`
 - host os: `Linux 5.15.167.4-microsoft-standard-WSL2, NixOS, 25.05 (Warbler), 25.05.20250503.f21e454`
 - multi-user?: `yes`
 - sandbox: `yes`
 - version: `nix-env (Nix) 2.28.3`
 - channels(root): `"nixos-24.11, nixos-wsl"`
 - nixpkgs: `/nix/store/qmm7hgw60vp7vj9lma95hl329d0j3n6n-source`
```

### home-manager

```zsh
> home-manager --version
25.05-pre
```

home-manager は、Flakes を利用してスタンドアロン型で導入しています。
### シェル

```zsh
> zsh --version
zsh 5.9 (aarch64-unknown-linux-gnu)
```

### その他

[GitHub アカウントへの新しい SSH キーの追加](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) で説明されている SSH キーの生成から GitHub アカウントへの SSH キーの追加までの作業を行っておく必要があるようです。と言いますのも、新しい環境でセットアップするために以下の手順を実施しても上手くいかなかったのですが、SSH キーの生成と追加を実施したらあっさりセットアップできましたので、理由不明ですが SSH キーの生成と追加は必要なようです。

### ファイル構成

```zsh
# 本論と関係しないファイルは適宜省略しています
.dotfiles
├── .git
│   ├── ...
│   ├── hooks
│   └── ...
├── .gitignore
├── .sops.yaml
├── configuration.nix
├── flake.lock
├── flake.nix
├── home
│   ├── git-pre-commit
│   └── zsh.nix
├── home.nix
├── secrets.yaml
└── sops
    └── age
```



## 大まかな作業の流れ

大まかな作業の流れは、暗号化したい API key を書き込んだファイルを sops 経由で作成し、ファイルを作成したら即座に age で暗号化し、暗号化したファイルを sops-nix による復号化を経由して NixOS で読み取るというものになります。

なお、この作業では秘密鍵や API key などの機密情報を扱いますので、設定をGit 管理する場合は機密情報の取り扱いが問題となります。この点は最後に説明しますが、注意点を申し上げておくと、この作業で API key や秘密鍵を格納したファイルは `git add` でステージングできるようにする必要がある、言い換えると、`.gitignore` に追加してはダメということです。理由は、この作業では Flakes で設定ファイルを取り扱いますが、Flakes は Git で管理していないファイルを取り扱えないため、機密情報を格納したファイルであっても Git で管理できる必要があるためです。言い換えると、機密情報を格納したファイルを `.gitignore` に列挙してはダメということです。私はこの点になかなか気付かず時間を溶かしてしまいました

## 必要なアプリなどのインストール

必要なアプリなどは以下の3つです。

- アプリ
  - [sops](https://github.com/getsops/sops)
  - [age](https://github.com/FiloSottile/age)
- モジュール
  - [sops-nix](https://github.com/Mic92/sops-nix)

アプリの sops が前置きで紹介した Mozilla 財団開発の暗号化ファイルエディタで、モジュールの sops-nix は sops を NixOS に組込むためのモジュールです。また、age は、Go 言語で書かれたシンプルかつモダンな暗号化ツールです。

なお、SSH キーから必要な鍵を生成する `ssh-to-pgp` というアプリもありますが、パスフレーズを設定した SSH キーから鍵を生成できないため、今回は使っていません。

### インストール

まずアプリからインストールします。アプリは home-manager でインストールしますので、`home.nix` を以下のとおり編集したら `git add .` してから `home-manager switch .` コマンドでインストールします。

```diff
home.packages = with pkgs; [
+  age
+  sops
];
```

それからモジュールをインストールします。公式リポジトリでは Flakes を使う方法が推奨されていますので、それに従って `flake.nix` を以下のとおり編集します。

```diff
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
+   sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    inputs:
    let
      # 各マシンのシステムタイプを定義する辞書
      systems = {
        desktop = "x86_64-linux";
        zenbook = "aarch64-linux";
      };

      # NixOS のシステム構成を作成するヘルパー関数
      mkNixosSystem =
        machine: system:
        inputs.nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ./configuration.nix
+           inputs.sops-nix.nixosModules.sops
          ];
        };

      # Home Manager のホーム構成を作成するヘルパー関数
      mkHomeManager =
        machine: system:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = system;
            config = {
              allowUnfree = true;
            };
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home.nix
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
      homeConfigurations = builtins.listToAttrs (
        map (machine: {
          name = "s-show@" + machine;
          value = mkHomeManager machine (systems.${machine});
        }) (builtins.attrNames systems)
      );
+     home-manager.sharedModules = [
+       inputs.sops-nix.homeManagerModules.sops
+     ];
    };
}
```

`flake.nix` を編集したら `git add .` してから `sudo nixos-rebuild switch --flake .#zenbook --impure --show-trace` で設定を反映させます。なお、[Windows on Arm の WSL2 で NixOS をインストールする方法 | 閑古鳥ブログ](./2025-04-20/index.html) で買いたとおり、私は1つの設定ファイルでデスクトップPCとノートPCを設定できるようにしているので、コマンド中にホスト名（`.#zenbook`）を指定していますが、そういうことをしていなければ `.#zenbook` は `.` になると思います。


## API key の暗号化

API key の暗号化の手順は次のとおりです。

1. 暗号化と復号化に使う公開鍵と秘密鍵のペアを作成する
1. 暗号化のルールを作成する
1. sops コマンド経由で API key を暗号化して保存する

### 鍵のペアを作成

まず、暗号化と復号化に使う鍵を格納したファイルを格納するためのディレクトリを用意します。

```bash
mkdir -p ~/.dotfiles/sops/age
```

それから、鍵ペアを生成してファイルに保存します。

```bash
age-keygen -o ~/.dotfiles/sops/age/keys.txt
```

コマンド実行後に公開鍵が表示されますので、どこかにコピーしておきます。コピーし忘れたときは、`age-keygen -y ~/.dotfiles/sops/age/keys.txt` で確認できます。

### 暗号化のルール作成

`touch ~/.dotfiles/.sops.yaml` で暗号化のルールを記述するためのファイルを作成したら、以下のとおりルールを記述します。

```yaml
# zenbook は私の環境のホスト名なので、適宜読み替えてください。
keys:
  - &zenbook (先程コピーした公開鍵を入力)
creation_rules:
  - path_regex: secrets.yaml$
    key_groups:
    - age:
      - *zenbook
```

### API key の暗号化

以下のコマンドを実行すると API key を保存するファイルのテンプレートが `$EDITOR` で指定しているエディタで開きます。

```zsh
# `secrets.yaml` は `.sops.yaml` の `path_regex` に合わせる
nix-shell -p sops --run "sops secrets.yaml"
```

ファイルが開いたら、環境変数の名前と API key を入力します。

```yaml
# API key を直接入力してから保存して閉じると自動的に暗号化される
OPENROUTER_API_KEY: ***
```

これで暗号化された API key が保存されました。

## 暗号化された API key を読み込む

`home.nix` を編集して、暗号化された API key を Nix で読み込んで環境変数にセットします。まず、`home.nix` を以下のとおり編集します。

```diff
home.packages = with pkgs; [
  ~~~
];

+ sops = {
+   age.keyFile = "/home/(username)/.dotfiles/sops/age/keys.txt"; # must have no password!
+   defaultSopsFile = ./secrets.yaml;
+   defaultSymlinkPath = "/run/user/1001/secrets";
+   defaultSecretsMountPoint = "/run/user/1001/secrets.d";
+ };

+ imports = [
+   inputs.sops-nix.homeManagerModules.sops
+ ];
```

編集したら `git add .` してから `home-manager switch .` を実行して設定を反映させます。エラーが出なければ次の編集に移ります。

```diff
sops = {
  age.keyFile = "/home/(username)/.dotfiles/sops/age/keys.txt";
  defaultSopsFile = ./secrets.yaml;
  defaultSymlinkPath = "/run/user/1001/secrets";
  defaultSecretsMountPoint = "/run/user/1001/secrets.d";
+  secrets.OPENROUTER_API_KEY = {
+    path = "${config.sops.defaultSymlinkPath}/OPENROUTER_API_KEY";
+  };
};

imports = [
  inputs.sops-nix.homeManagerModules.sops
];
```

編集したら再び `git add .` してから `home-manager switch .` を実行して設定を反映させます。エラーが出なければ `./home/zsh.nix` を編集します（ZSH の設定は `home.nix` から読み込む形にしています）。

```diff
+ programs.zsh = {
+   initContent = ''
+     export OPENROUTER_API_KEY=$(cat ${config.sops.secrets.OPENROUTER_API_KEY.path})
+   '';
+ };
```

編集後は `git add .` してから `home-manager switch .` を実行して設定を反映させます。エラーが出なければ NixOS を再起動します。再起動後にシェルで `echo $OPENROUTER_API_KEY` を実行して環境変数が設定されているか確認します。上手く設定できていれば API key が表示されると思います。

なお、上記の説明では `home.nix` の設定を細切れにして適用していますが、最初は全部まとめて設定していました。しかし、何度試してもエラーになってしまうので、上記のとおり分割して適用したところ上手くいきました。そのため、本記事では上記のとおり説明しています。

## Git の設定

設定ファイルを Git で管理している場合、暗号化した API key が格納されている `secrets.yaml` や、秘密鍵が格納されている `sops/age/keys.txt` を GitHub にプッシュしてしまう事態を避ける必要があります。

しかし、これらのファイルを `.gitignore` に列挙して Git の追跡対象外にすると Flakes が認識しなくなって設定できなくるってしまいます。そこで色々悩んだのですが、とりあえず「プッシュするにはコミットする必要があるので、コミットできないようにすれば何とかなるだろう」と考えました。

そこで、Git の pre-hook 機能を使って「指定した名前のファイルをコミットしようとしたらブロックする」という機能を追加しました。その方法ですが、まず `./home/git-pre-commit` ファイルを作成して以下のスクリプトを書きました。

```bash
#!/usr/bin/env bash

# コミットをブロックするファイルのリスト
blocked_files="secrets.yaml keys.txt .sops.yaml"

# コミット対象のファイルを取得
staged_files=$(git diff --cached --name-only)

for file in $staged_files; do
  for blocked_file in $blocked_files; do
    if [ "$(basename $file)" = "$blocked_file" ]; then
      echo "機密保持のため $blocked_file のコミットは禁止！"
      exit 1
    fi
  done
done
```

それから、`chmod +x .dotfiles/home/git-pre-commit` でスクリプトに実行権限を付与してから、`./home/zsh.nix` に以下の設定を追加しました。

```diff
 programs.zsh = {
   initContent = ''
     export OPENROUTER_API_KEY=$(cat ${config.sops.secrets.OPENROUTER_API_KEY.path})
+    cp "${builtins.toString config.home.homeDirectory}/.dotfiles/home/git-pre-commit" "${builtins.toString config.home.homeDirectory}/.dotfiles/.git/hooks/pre-commit"
   '';
 };
```

これで ZSH 起動時にこのスクリプトが `./.git/hooks` ディレクトリに `pre-commit` というファイル名でコピーされ、`secrets.yaml` や `keys.txt` をコミットしようとするとブロックできるようになりました。洗練された方法とは言い難いですが、機密情報をプッシュする事態は避けられるのでとりあえずヨシとしています。

## 参考情報

[Comparison of secret managing schemes - NixOS Wiki](https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes) は NixOS で機密情報を扱うための手段を比較したページです。

[Managing Secrets in NixOS Home Manager with SOPS](https://zohaib.me/managing-secrets-in-nixos-home-manager-with-sops/) は具体的な手順を紹介しているページです。ただ、このページは home-manager を NixOS のモジュールとしてインストールしているので、私のようにスタンドアロンでインストールしている場合はそのまま適用できません。本記事はこのページの情報を元に悪戦苦闘した結果でもあります。

