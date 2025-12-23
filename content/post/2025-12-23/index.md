---
title: "zeno.zsh のメモ" # Title of the blog post.
date: 2025-12-23T21:53:48+09:00 # Date of post creation.
featured: false
draft: false
comment: true
toc: false
tags: [CLI, 備忘録]
archives: 2025/12
---


## 前置き

[ターミナルでメモ管理 (Neovim, nb, zeno.zsh)](https://zenn.dev/mozumasu/articles/mozumasu-cli-info-management) を見て、zeno.zsh の補完機能に魅力を感じて導入を決めました。これまで abbrev については [zsh-abbr](https://zsh-abbr.olets.dev/) で対応していたのですが、1つのプラグインで abbrev と補完の両方を実現できる点も良いと思いました。

導入してみたところ、最初は設定でちょっとつまづいたのですが、使えるようになると非常に便利でしたので、備忘録として設定のポイントをまとめます。

## zeno.zsh とは？

Deno を用いて開発された ZSH/Fish のプラグインで、主な機能は以下のとおりです。

- abbrev を用いた snippet の展開
- ファジーファインダー (fzf) を用いた補完
- fzf を用いた snippet の挿入
- fzf を用いたコマンド履歴検査と実行

## 環境

```bash
> zsh --version
zsh 5.9 (x86_64-pc-linux-gnu)

> deno --version
deno 2.5.6 (stable, release, x86_64-unknown-linux-gnu)
v8 14.0.365.5-rusty
typescript 5.9.2

> fzf --version
0.67.0 (v0.67.0)
```

## インストール

公式リポジトリでは [zdharma-continuum/zinit: 🌻 Flexible and fast ZSH plugin manager](https://github.com/zdharma-continuum/zinit) や `git clone` でインストールする方法が紹介されていますが、私は Nix の Home Manager を使って [rossmacarthur/sheldon: :bowtie: Fast, configurable, shell plugin manager](https://github.com/rossmacarthur/sheldon) をインストールしたうえで、sheldon 経由でインストールしました。

```toml
# ~/.config/sheldon/plugins.toml
shell = "zsh"

[plugins]

[plugins.zeno]
 github = "yuki-yano/zeno.zsh"

[plugins.fast-syntax-highlighting]
 github = "zdharma-continuum/fast-syntax-highlighting"
```

また、zeno.zsh は [Deno, the next-generation JavaScript runtime](https://deno.com/) と [junegunn/fzf: :cherry\_blossom: A command-line fuzzy finder](https://github.com/junegunn/fzf) が必要なので、これらもインストールする必要があります。

## zeno.zsh の基本設定

公式リポジトリに従って `~/.zshrc` に以下のコードを追加しました。`ZENO_HOME` については、自分の環境に合わせて設定しています。キーバインドについては、ひとまず公式と同じキーバインドに設定しています。

```zshrc
export ZENO_HOME=~/.config/zsh/zeno

# git file preview with color
export ZENO_GIT_CAT="bat --color=always"

# git folder preview with color
# export ZENO_GIT_TREE="eza --tree"

if [[ -n $ZENO_LOADED ]]; then
  bindkey ' '  zeno-auto-snippet

  # if you use zsh's incremental search
  # bindkey -M isearch ' ' self-insert
  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^i' zeno-completion
  # open snippet picker (fzf) and insert at cursor
  bindkey '^xx' zeno-insert-snippet
  bindkey '^x '  zeno-insert-space
  bindkey '^x^m' accept-line
  bindkey '^x^z' zeno-toggle-auto-snippet
  # preprompt bindings
  bindkey '^xp' zeno-preprompt
  bindkey '^xs' zeno-preprompt-snippet
  # Outside ZLE you can run `zeno-preprompt git {{cmd}}` or `zeno-preprompt-snippet foo`
  # to set the next prompt prefix; invoking them with an empty argument resets the state.
  bindkey '^r' zeno-smart-history-selection # smart history widget

  # fallback if completion not matched
  # (default: fzf-completion if exists; otherwise expand-or-complete)
  # export ZENO_COMPLETION_FALLBACK=expand-or-complete
fi
```

これでセッションを再起動すれば zeno.zsh が読み込まれますので、次はスニペットや補完の設定を始めていきます。

## スニペットや補完の設定の保存場所など

### 起動時に読み込むディレクトリ

zeno.zsh は起動時に以下の順番でディレクトリを読み込んで設定を反映させます。また、設定ファイルは YAML と TypeScript の両方が使えます。

(公式リポジトリより引用)
> - zeno loads configuration files from the project and user config directories and merges them in priority order.
> - If the current workspace has a `.zeno/` directory, its contents are loaded first, followed by the user config directory (`$ZENO_HOME` or `~/.config/zeno/`), and finally any XDG config directories.
> - Within each location, files are merged alphabetically.
> - Both YAML (`*.yml`, `*.yaml`) and TypeScript (`*.ts`) files are supported, so you can pick the format that suits your workflow.
> - TypeScript configs can import `defineConfig` and types from `jsr:@yuki-yano/zeno`, giving you access to the full `ConfigContext` for dynamic setups.

【拙訳】
> - zeno は設定ファイルをプロジェクトおよびユーザー設定ファイルのディレクトリから読み込み、それらを優先順位に沿って統合する。
> - カレントワークスペースに `.zeno/` ディレクトリがあるならば、そこの設定ファイルが最初に読み込まれる。次にユーザー設定ファイルのディレクトリ (`$ZENO_HOME` or `~/.config/zeno/`) が対象になり、最後に任意の XDG ディレクトリが対象になる。
> - 各場所において、ファイルはアルファベット順に統合される。
> - YAML (`*.yml`, `*.yaml`) と TypeScript (`*.ts`) ファイルの両方がサポートされるので、ワークフローに適したフォーマットを選択できる。

このような動作になっているため、例えば、特定のディレクトリだけで有効なスニペットや補完を設定することも可能です。その場合、そのディレクトリに `.zeno/` ディレクトリを作成し、そのディレクトリに設定ファイルを作成すれば OK です。

### ユーザー設定ファイルの読み込み

zeno.zsh は以下のとおり設定ファイルを読み込んで設定を反映させる。

(公式リポジトリより引用)
> - If the detected project root contains a `.zeno/` directory, load all `.zeno/*.yml`/`*.yaml`/`*.ts` (A→Z).
> - If `$ZENO_HOME` is a directory, merge all `*.yml`/`*.yaml`/`*.ts` directly under it.
> - For each path in `$XDG_CONFIG_DIRS`, if `zeno/` exists, merge all `zeno/*.yml`/`*.yaml`/`*.ts` (directories are processed in the order provided by XDG).
> - Fallbacks for backward compatibility (used only when no files were found in the locations above):
>   - `$ZENO_HOME/config.yml`
>   - `$XDG_CONFIG_HOME/zeno/config.yml` or `~/.config/zeno/config.yml`
>   - Find `.../zeno/config.yml` from each in `$XDG_CONFIG_DIRS`

【拙訳】
> - プロジェクトのルートディレクトリに `.zeno/` ディレクトリがあれば、その中にある `.zeno/*.yml`/`*.yaml`/`*.ts` を全てロードする。
> - `$ZENO_HOME` がディレクトリを指しているならば、その配下にある `*.yml`/`*.yaml`/`*.ts` を全てマージする。
> - `$XDG_CONFIG_DIRS` の各パスに `zeno/` ディレクトリが存在するならば、`.zeno/*.yml`/`*.yaml`/`*.ts` を全てマージする（ディレクトリの順番は、XDG の順番どおりに進む）
> - 後方互換性のためのフォールバックは以下のとおり（上記の場所でファイルが見つからないときだけ使われる）
>   - `$ZENO_HOME/config.yml`
>   - `$XDG_CONFIG_HOME/zeno/config.yml` または `~/.config/zeno/config.yml`
>   - `$XDG_CONFIG_DIRS` の各パスから見た `.../zeno/config.yml`

## コマンド履歴

`<ctrl-r>` をタイプするとコマンド履歴が fzf で開くので、適宜絞り込みをかけて履歴からコマンドを実行できます。

fzf には純正のコマンド履歴機能がありますが、zeno.zsh のコマンド履歴はコマンドの実行時間などがプレビューで表示されるので、より高機能になっています。

## 補完機能の設定

補完設定は `.yaml` と `.ts` の両方で記述できますので、ここでは TypeScript の場合の書き方をメモしていきます。

設定では `defineConfig()` 関数を使うので、"jsr:@yuki-yano/zeno" からインポートします。

```typescript
import { defineConfig } from "jsr:@yuki-yano/zeno";
```

それから、`defineConfig()` 関数のコールバック関数に補完設定の配列を記述していきます。

コールバック関数に引数として渡される `projectRoot` と `currentDirectory` にはプロジェクトのルートディレクトリと現在のディレクトリの絶対パスが入っていますので、これらを利用することもできます。

### 補完設定のオプション

自分の設定で使っているオプションは以下のとおりです。

- `name`: 補完設定の名前。任意の名前を指定する
- `patterns`: 補完を発動させる場合の条件を指定する
- `excludePatterns`: 補完を発動させない場合の条件を指定する
- `sourceCommand`: 補完候補を取得するためのコマンドを指定する
- `sourceFunction`: `sourceCommand` では対応できない複雑な補完候補を取得する場合に指定する
- `options`: fzf に渡されるオプションを指定する
    - `--prompt`: クエリ入力欄の前に表示される文字列を指定する。補完候補を選択した後はこの文字列がターミナルに挿入される。
    - `--multi`: 補完候補を複数選択する場合に `true` を指定する
    - `--read0`: fzf に渡される文字列を NULL 文字区切りとして扱う
    - `--preview`: 選択した補完候補をプレビューするためのコマンドを指定する
    - `--ansi`: ANSI カラーコードを有効化するときに指定する
- `callback`: 補完候補を選択した後、その選択した補完文字列に対して実行する処理を指定する。
- `callbackZero`: 選択した補完文字列を `callback` のコマンドに渡す際に NULL 文字区切りとして渡す。`--read0: true` とセットで指定する。

### 補完設定の例

```typescript
import { defineConfig } from "jsr:@yuki-yano/zeno";

export default defineConfig(({ projectRoot, currentDirectory }) => ({
  completions: [
    {
      name: "kill pid",
      patterns: [
          "^kill( .*)? $",
      ],
      excludePatterns: [
          " -[lns] $",   // kill -l, kill -n, kill -s では補完が発動しない
      ],
      sourceCommand: "LANG=C ps -ef | sed 1d",
      options: {
          "--multi": true,
          "--prompt": "'Kill Process> '",
      },
      callback: "awk '{print $2}'",
    },
    {
      name: "cd",
      patterns: ["^cd $"],
      sourceCommand:
        "find . -path '*/.git' -prune -o -maxdepth 5 -type d -print0",
      options: {
        "--read0": true,
        "--prompt": "'Chdir> '",
        "--preview": "cd {} && ls -a | sed '/^[.]*$/d'",
      },
      callback: "cut -z -c 3-",
      callbackZero: true,
    },
    {
      name: "nb edit",
      patterns: [
        "^nb e( .*)? $",
        "^nb edit( .*)? $",
      ],
      sourceCommand: "nb ls --no-color | rg '^\\[[0-9]+\\]'",
      options: {
        "--ansi": true,
        "--prompt": "'nb edit > '",
        "--preview": "echo {} | sed -E 's/^\\[([0-9]+)\\].*/\\1/' | xargs nb show"
      },
      callback: "sed -E 's/^\\[([0-9]+)\\].*/\\1/'"
    },
    {
      name: "npm scripts",
      patterns: [
        "^pnpm $",
      ],
      sourceFunction: async ({ projectRoot }) => {
        try {
          const pkgPath = join(projectRoot, "package.json");
          const pkg = JSON.parse(
            await Deno.readTextFile(pkgPath),
          ) as { scripts?: Record<string, unknown> };
          return Object.keys(pkg.scripts ?? {});
        } catch {
          return [];
        }
      },
      options: {
        "--prompt": "'pnpm scripts> '",
      },
      callback: "pnpm {{}}",
    },
  ],
}));
```

### 補完の呼び出し

`patterns` で指定した文字列を入力してから、`ctrl-i` または `tab` をタイプすると fzf で補完候補が表示されます。

## スニペット機能の設定

どちらかというと fish の abbreviations（略語展開）に近い機能です。補完と同様に `.yaml` と `.ts` の両方で設定できます。

設定では `defineConfig()` 関数を使うので、"jsr:@yuki-yano/zeno" からインポートします。

```typescript
import { defineConfig } from "jsr:@yuki-yano/zeno";
```

そして、補完と同様に `defineConfig()` 関数のコールバック関数に設定の配列を記述していきます。

### スニペット設定のオプション

自分の設定で使っているオプションとそれ以外のオプションは以下のとおりです。なお、文字だけでは挙動が掴みにくいものもあると思いますので、設定例に簡単な動作もコメントで記載しています。

- `name`: スニペットの名前。任意の名前を指定する
- `keyword`: スニペットの略語を指定する
- `snippet`: 展開後のコマンド文字列を指定する。展開後にカーソルを移動させたい場所がある場合、`{{hoge}}` の形で指定する。`hoge` の部分は任意の文字列でOK。
- `context`: スニペット展開の条件を指定する。デフォルトの展開条件は「`keyword` が行頭にある場合」である。
    - `lbuffer`: カーソルの左側に指定した文字列がある場合のみ展開したい場合に指定する
    - `rbuffer`: カーソルの右側に指定した文字列がある場合のみ展開したい場合に指定する
    - `global`: `keyword` がどこにあっても展開したい場合に `true` を指定する
    - `buffer`: 指定した正規表現に該当する文字列があれば、`keyword` がどこにあっても展開される
- `evaluate`: `keyword` で指定した文字列を `snippet` で指定したコマンドの結果で置き換える場合に指定する

### スニペット設定の例

```typescript
import { defineConfig } from "jsr:@yuki-yano/zeno";

export default defineConfig(({ projectRoot, currentDirectory }) => ({
  snippets: [
    {
      name: "git commit",
      keyword: "gm"
      snippet: "git commit -m {{commit message}}",
    },
    {
      name: "QMK compile",
      keyword: "compile"
      snippet: "qmk compile -kb {{keyboard}} -km {{keymap}}",
      // 展開すると `{{keyboard}}` のところにカーソルが移動する。それから `ctrl-x p` と入力して
      // `zeno-preprompt` コマンドを呼び出すと `{{keymap}}` のところにカーソルが移動する。
    },
    {
      name: "branch",
      keyword: "B",
      snippet: "git symbolic-ref --short HEAD",
      context: {
          lbuffer: "^git\\s+checkout\\s+",
      },
      evaluate: true,
      // `git checkout B<space>` が `git checkout {現在のブランチ名}` に展開される
    },
    {
      name: "test",
      keyword: "full",
      snippet: "echo 'hogehoge'",
      context: {
        buffer: "^git.*commit.*$",
      },
      // `^git.*commit.*$` を満たしていれば、`full` が `echo 'hogehoge'` に展開される
      // ex) `git commit` -> `git full<space> commit` -> `git echo 'hogehoge' commit`
    },
    {
      name: "ls",
      keyword: "ls",
      snippet: "eza --icons always --long --git {{foo_bar}}",
    },
    {
      name: "test2",
      keyword: "G",
      snippet: "echo 'global!'",
      context: {
        global: true,
      },
      // `G` をどこに入力しても `echo 'global!'` に展開される
      // ex) `git commit` -> `git G<space> commit` -> `git echo 'global!' commit`
    },
    {
      name: "test3",
      keyword: "cdp",
      snippet: `exa ${projectRoot}`,
      // `${projectRoot}` が現在のプロジェクトのルートディレクトリに置き換えされる
      // ex) `cdp<space>` -> `exa /path/to/project_root_directory`
    },
  ],
}));
```

### スニペットの展開

`keyword` で設定した文字列を入力してから `<space>` を入力すると展開されます。また、`keyword` で設定した文字列を入力してから `<enter>` を入力すると展開してから実行されます。

また、`keyword` を入力しなくても、`ctrl-x x` で `zeno-insert-snippet` を呼び出すと設定したスニペットが fzf で表示されるので、そこから選択することも可能です。

さらに、`ctrl-x s` で `zeno-preprompt-snippet` を呼び出すと、設定したスニペットが fzf で表示されるので、そこから選択することも可能です。

`zeno-insert-snippet` と `zeno-preprompt-snippet` の違いは、前者は選択したスニペットを挿入する処理なので、入力済みコマンドはそのまま残っているのに対し、後者は選択したスニペットで入力済みコマンドを置き換えてしまう点です。

### スニペットのキーワードをキーワードのまま入力したい場合の方法

上記の設定で `ls` を実行する場合、`ls<ctrl-x><ctrl-m>` とタイプすれば `ls` が `eza --icons always --long --git {{foo_bar}}` に展開されることなく実行できます。

また、`ls -la` を実行する場合、`ls<ctrl-x><space>` とタイプすれば `eza --icons always --long --git {{foo_bar}}` に展開されることなくスペースを入力できます。

さらに、`<ctrl-x><ctrl-z>` をタイプして `zeno-toggle-auto-snippet` コマンドを実行すると、展開機能をオフにできます。もう一度 `<ctrl-x><ctrl-z>` をタイプすれば展開機能をオンにできます。

## まとめ

zeno.zsh は設定に少し時間がかかりましたが、一度設定してしまえば非常に便利に使えるツールです。特に、補完機能とスニペット展開を1つのプラグインで実現できる点が気に入っています。

本記事がどなたかの参考になれば幸いです。

## 参考にしたサイト

- [yuki-yano/zeno.zsh: zeno.zsh is a new generation zsh plugin](https://github.com/yuki-yano/zeno.zsh)
- [Deno + TypeScriptでzshプラグインを実装して最高になった](https://zenn.dev/yano/articles/zsh_plugin_from_deno)
- [ターミナルでメモ管理 (Neovim, nb, zeno.zsh)](https://zenn.dev/mozumasu/articles/mozumasu-cli-info-management)
- [zshの補完をサクッと作れる便利プラグインzeno.zshの使い方 | eiji.page](https://eiji.page/blog/zeno-zsh-intro/)
- [yuki-yano/zeno.zsh | DeepWiki](https://deepwiki.com/yuki-yano/zeno.zsh)

