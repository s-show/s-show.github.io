---
title: "tmux の設定メモ（主にプラグイン関係）"
date: 2025-12-31T00:00:00+09:00
featured: false
draft: false
comment: true
toc: false
tags: [neovim,tmux]
archives: 2025/12
---

## 前置き

ターミナルマルチプレクサに [Zellij](https://zellij.dev/) を使っていますが、[timg](https://github.com/hzeller/timg) で画像を表示すると画面表示が壊れてしまうという問題に直面していました。しかし、この問題を Google Gemini に相談したら「Zellij 側の問題なので Zellij の対応を待つしかない」と回答されてしまいました。なお、CLI のファイラーの [Yazi](https://yazi-rs.github.io/) の [サポートページ](https://yazi-rs.github.io/docs/image-preview/#zellij) でも以下のとおり記載されており、本当に Zellij の対応を待つしかないという状況のようです。

> Zellij currently only supports the Sixel graphics format, so you will need a terminal that also supports Sixel.
> Note that, Zellij's Sixel implementation is quite buggy and has serious performance issues at the moment, causing noticeable lagginess when quickly switching between images, and sometimes even image tearing or not working at all.
> This situation won't improve until Zellij enhances its Sixel implementation or provides a passthrough mode. If the image is a stronger need to you, consider running Yazi outside of Zellij or using Überzug++:
> (DeepL 翻訳)
> Zellijは現在Sixelグラフィック形式のみをサポートしているため、Sixelをサポートする端末が必要です。 なお、ZellijのSixel実装は現時点でバグが多く、深刻なパフォーマンス問題を抱えています。画像の切り替えが速い場合に顕著な遅延が発生し、画像のティアリングや動作不能になることもあります。 この状況は、ZellijがSixel実装を強化するかパススルーモードを提供するまで改善されません。画像表示がより重要な要件である場合は、Zellij外でYaziを実行するか、Überzug++の使用をご検討ください：

また、Zellij のデフォルトキーマッピングは Neovim と衝突しがちなので、衝突を避けるために [tmux/tmux: tmux source code](https://github.com/tmux/tmux) のように `<ctrl-b>` をタイプしてから別のキーを押す設定にしていましたが、上記の画像表示の問題と合わさって、tmux に乗り換えた方が良いのではと思うようになっていました。

そこで試しに tmux を使ってみたら timg の画像表示も問題なくできて操作にも慣れることができそうだったので、思い切って zellij から tmux に乗り換えてみることにしました。

ただ、プラグインのインストール関係で色々トラブルがあったため、備忘録としてどのような問題に遭遇したが、なぜその問題が発生したのか、どうやって対処したかを整理します。

## 環境

### OS

NixOS on WSL2

```bash
> uname -a
Linux desktop 5.15.167.4-microsoft-standard-WSL2 #1 SMP Tue Nov 5 00:21:55 UTC 2024 x86_64 GNU/Linux
```

### Nix

```bash
> nix-shell -p nix-info --run "nix-info -m"
 - system: `"x86_64-linux"`
 - host os: `Linux 5.15.167.4-microsoft-standard-WSL2, NixOS, 26.05 (Yarara), 26.05.20251201.0d70460`
 - multi-user?: `yes`
 - sandbox: `yes`
 - version: `nix-env (Nix) 2.31.2`
 - channels(root): `"nixos-24.11, nixos-wsl"`
 - nixpkgs: `/nix/store/jvnng29zlymijsna49wqma0hfx49zhx7-source`
```

### home-manager

```
home-manager -> stateVersion = "25.05"
```

home-manager は NixOS のモジュールとして導入しています。

### シェル

```zsh
> zsh --version
zsh 5.9 (x86_64-pc-linux-gnu)
```

## インストールに苦労したプラグイン

- tmux-menus

## 動作させるのに苦労したプラグイン

- tmux-menus
- tmux-which-key
- tmux-mode-indicator

## tmux-menus の苦労した理由

tmux-menus は、`<prefix>\` でウィンドウ操作などを実行できるポップアップメニューを表示してくれるプラグインです。tmux には Zellij のように画面下に主なキーバインドを表示する機能はないので、キーバインドを覚えるまでの補助として導入することにしました。

### インストール

まず、tmux-menus は Nix パッケージで配付されていないため、最初はプラグインをインストールする方法を探すところからスタートしました。

最初は `pkgs.fetchurl` を使ってビルドするのかと思いましたが、[Setting Up Tmux With Nix Home Manager | Haseeb Majid](https://haseebmajid.dev/posts/2023-07-10-setting-up-tmux-with-nix-home-manager/) で `pkgs.tmuxPlugins.mkTmuxPlugin` を使って Nix パッケージで配付されていないプラグインを使う方法が紹介されていましたので、そちらを参考にしました。ただし、`hash` と指定すべきところが `sha256` となっていたせいで最初はエラーに悩まされました。

ビルドに成功した時点の設定は以下のとおりです。

```nix
let
    tmux-menus = pkgs.tmuxPlugins.mkTmuxPlugin {
    │ pluginName = "tmux-menus";
    │ version = "v2.2.33";  # 2025/12/29 時点の最新版
    │ src = pkgs.fetchFromGitHub {
    │ ┊ owner = "jaclu";
    │ ┊ repo = "tmux-menus";
    │ ┊ rev = "879f56df1b9703ac277fa16b9bbaf8705f2e6a1c";
    │ ┊ hash = "sha256-UPWsa7sFy6P3Jo3KFEvZrz4M4IVDhKI7T1LNAtWqTT4=";
    │ };
    };
in
{
│ programs.tmux = {
│ │ enable = true;
│ │ plugins = with pkgs; [
┃ │ ┊ {
┃ │ ┊ ┆ plugin = tmux-menus;
┃ │ ┊ ┆ extraConfig = ''
┃ │ ┊ ┆ ¦ set -g @plugin 'jaclu/tmux-menus'
┃ │ ┊ ┆ '';
┃ │ ┊ }
    ]
  }
}
```

### `rtpFilePath` の指定もれ

インストールできたかテストするためデフォルトキーマッピングの `<prefix>\` をタイプしましたが、何回タイプしてもプラグインが実行される様子がありませんでした。

原因の見当が付かなかったので Claude Code に相談したところ、`mkTmuxPlugin` 関数の引数の1つである `rtpFilePath` が指定されていないことが原因だと指摘されました。

`mkTmuxPlugin` 関数の `rtpFilePath` 引数は、Tmux が読み込むべき設定ファイル（エントリーポイント）のファイル名を指定する引数で、未指定だとプラグイン名の `-` を `_` に変換して `.tmux` 拡張子を付与したファイルを読み込むようになっています。そのため、`tmux-menus` の場合、`tmux_menus.tmux` というファイルを読み込もうとします。

大半のプラグインはこの方法で動作しますが、tmux-menus の設定ファイルは `tmux_menus.tmux` ではなく `menus.tmux` なので、tmux-menus は存在しないファイルを読み込もうとしてエラーになっていました。

よって、この問題は `rtpFilePath` に `menus.tmux` を指定することで解決できました。

```nix
let
    tmux-menus = pkgs.tmuxPlugins.mkTmuxPlugin {
    │ pluginName = "tmux-menus";
      rtpFilePath = "menus.tmux";  # ← これを追加
    │ version = "v2.2.33";
    │ src = pkgs.fetchFromGitHub {
    │ ┊ owner = "jaclu";
    │ ┊ repo = "tmux-menus";
    │ ┊ rev = "879f56df1b9703ac277fa16b9bbaf8705f2e6a1c";
    │ ┊ hash = "sha256-UPWsa7sFy6P3Jo3KFEvZrz4M4IVDhKI7T1LNAtWqTT4=";
    │ };
    };
in
{
│ programs.tmux = {
│ │ enable = true;
│ │ plugins = with pkgs; [
┃ │ ┊ {
┃ │ ┊ ┆ plugin = tmux-menus;
┃ │ ┊ ┆ extraConfig = ''
┃ │ ┊ ┆ ¦ set -g @plugin 'jaclu/tmux-menus'
┃ │ ┊ ┆ '';
┃ │ ┊ }
    ]
  }
}
```

### 書き込み不可ディレクトリへの書き込み

設定ファイルを読み込めるようになったのに動作しないので追加調査したところ、tmux-menus が `/nix/store` ディレクトリにキャッシュを書き込もうとして失敗していることが判明しました。

具体的には、`tmux-menus/scripts/utils/cache.sh` で定義されている `cache_create_folder()` 関数が `mkdir -p "$d_cache"` でキャッシュ用ディレクトリを作成しようとしますが、`$d_cache` 変数の元となる `$D_TM_BASE_PATH` 変数は `/nix/store/.../tmux-menus` となっている（`tmux-menus/menus.tmux` での処理）ため、`$d_cache` の値が `/nix/store/.../tmux-menus/cache` になってしまい、書き込みに失敗してしまいます。

パフォーマンス向上のためにキャッシュを用意しようとしているのですが、プラグインが動かないのでは意味がないので、`set -g @menus_use_cache 'No'` を追加してキャッシュ用ディレクトリを作成しないようにして解決しました。

これらの問題解決後の設定は以下のとおりです。

```nix
let
    tmux-menus = pkgs.tmuxPlugins.mkTmuxPlugin {
    │ pluginName = "tmux-menus";
      rtpFilePath = "menus.tmux";  # ← これを追加
    │ version = "v2.2.33";
    │ src = pkgs.fetchFromGitHub {
    │ ┊ owner = "jaclu";
    │ ┊ repo = "tmux-menus";
    │ ┊ rev = "879f56df1b9703ac277fa16b9bbaf8705f2e6a1c";
    │ ┊ hash = "sha256-UPWsa7sFy6P3Jo3KFEvZrz4M4IVDhKI7T1LNAtWqTT4=";
    │ };
    };
in
{
│ programs.tmux = {
│ │ enable = true;
│ │ plugins = with pkgs; [
┃ │ ┊ {
┃ │ ┊ ┆ plugin = tmux-menus;
┃ │ ┊ ┆ extraConfig = ''
┃ │ ┊ ┆ ¦ set -g @plugin 'jaclu/tmux-menus'
┃ │ ┊ ┆ ¦ set -g @menus_use_cache 'No'  # ← これを追加
┃ │ ┊ ┆ '';
┃ │ ┊ }
    ]
  }
}
```


## tmux-which-key の問題

tmux-which-key は、`<prefix><space>` で `<prefix>` の次に押すキーの候補と説明を表示してくれるプラグインです。tmux-menus と似ているプラグインですが、どちらが馴染むか分からなかったので、両方使ってみることにしました。

tmux-which-key は Nix パッケージとして配付されているので簡単にインストールできましたが、インストール後に `<prefix><space>` をタイプするとレイアウト変更が実行されるので、何らかのエラーが発生していることは分かりましたが、原因の見当が付きませんでした。

この問題についても Claude Code に相談したところ、tmux-menus と同じく、書き込み不可ディレクトリに書き込みしようとしていることが原因だと指摘されました。

具体的には、`set -g @tmux-which-key-xdg-enable=1` を指定していない場合、設定ファイルの `config.yaml` と `init.tmux` を `/nix/store/...-tmux-which-key/` に作成しようとするので、書き込み不可でエラーになってしまいます。

この問題については、`set -g @tmux-which-key-xdg-enable=1` とすることで無事解決しました。なお、`set -g @tmux-which-key-xdg-enable=1` は、`config.yaml` と `init.tmux` を `~/.config/tmux/plugins/tmux-which-key/config.yaml` と `~/.local/share/tmux/plugins/tmux-which-key/init.tmux` に作成させるためのオプションです。

しかし、`init.tmux` は `config.yaml` の内容を `build.py` が読み取って作成しますが、なぜか `init.tmux` が読み取り専用になっていて編集不可だったため、実行できない状態が続いていました。

この問題については、home-manager に `init.tmux` を生成させるのではなく、あらかじめ `init.tmux` を自前で用意し、それを `mkDotfileSymlink` 関数を使って `~/.local/share/tmux/plugins/tmux-which-key/init.tmux` にリンクさせることで対処することにしました。

## tmux-mode-indicator が読み込まれない問題

tmux-mode-indicator は、通常モード・copy モード・sync モード（複数 pane に同時に入力）・prefix モード（`<prefix>` の次のキーを待機している状態）に入ったときにモードに応じたインジケータをステータスラインに表示してくれるプラグインです。Zellij に同様の機能があるので tmux でも導入してみることにしました。

tmux-mode-indicator も Nix パッケージとして配付されているためインストールは簡単でしたが、[公式リファレンス](https://github.com/MunifTanjim/tmux-mode-indicator) と同じ設定にしてもインジケータが表示されませんでした。

この問題についても Claude Code に相談したところ、別途インストールしていた Nord テーマが `status-left` を編集して tmux-mode-indicator の設定を上書きしていたことが原因だと判明しました。

そのため Nord テーマを削除してセッションを再起動したら直ったものの、デフォルトテーマでは味気ないので [o0th/tmux-nova: tmux theme](https://github.com/o0th/tmux-nova) をインストールすることにしました。Nord を再インストールしなかった理由は、[Nord](https://www.nordtheme.com/ports/tmux) を見てもあまり細かく設定できそうに見えなかったため、また同じ問題が発生するのではないかと思ったためです。

ただ、tmux-nova は細かい設定ができるので、結局、tmux-mode-indicator でできることを tmux-nova に置き換えてしまいました。そのため、tmux-mode-indicator は使わなくなってしまいました。

## tmux-nova の設定

tmux-nova はインストールも設定もそこまで苦労しなかったので、tmux-mode-indicator の機能を取り入れる部分だけメモします。

公式リポジトリの [gallery.md](https://github.com/o0th/tmux-nova/blob/master/.github/gallery.md) の gruvbox の設定を一部変更しています。

```diff
- set -g @nova-segment-prefix "#{?client_prefix,PREFIX,}"
+ set -g @nova-segment-prefix ["\
+ #{?client_prefix,PREFIX ,\
+ #{?#{m:copy-mode,#{pane_mode}},COPY ,\
+ #{?#{m:tree-mode,#{pane_mode}},TREE ,\
+ #{?#{pane_in_mode},SELECT ,\
+ #{?pane_synchronized,SYNC ,TMUX \
+ }}}}}}]\
+ [#S]"

- set -g @nova-segments-0-left "session"
+ set -g @nova-segments-0-left "prefix session"
- set -g @nova-segments-0-right "prefix cpu battery layout whoami"
+ set -g @nova-segments-0-right "whoami"
```

`@nova-segment-prefix` の部分でモード表示を設定していますが、ここでは tmux の `#{?条件式, 真の場合の処理, 偽の場合の処理}` という条件分岐と `{?#{m:マッチングさせたい文字列,調べたい変数}}, 真の場合の処理, 偽の場合の処理` をネストしてモード毎に表示する文字列を変更しています。

## 参考にしたサイト

- [Setting Up Tmux With Nix Home Manager | Haseeb Majid](https://haseebmajid.dev/posts/2023-07-10-setting-up-tmux-with-nix-home-manager/)
- [jaclu/tmux-menus: Tmux plugin that provides a better way to manage your tmux menus](https://github.com/jaclu/tmux-menus)
- [alexwforsythe/tmux-which-key: Show keybindings in a popup](https://github.com/alexwforsythe/tmux-which-key)
- [MunifTanjim/tmux-mode-indicator: Plugin that displays prompt indicating currently active Tmux mode.](https://github.com/MunifTanjim/tmux-mode-indicator)
- [o0th/tmux-nova: tmux theme](https://github.com/o0th/tmux-nova)
