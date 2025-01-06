---
title: Github Actions で Re:view Starter のファイルをビルドする方法
date: 2021-12-11T08:00:00+09:00
draft: false
---

## 前置き

今年の3月から部下に業務遂行のバックグラウンドとなる知識を伝えるための勉強会を開いており、そのための資料を [RE:View Starter](https://qiita.com/kauplan/items/d01e6e39a05be0b908a1) で作成しています。

勉強会の都度その回の資料を執筆し、ビルドして出来た PDF ファイルを職場にメールで送っているのですが、送り忘れた場合に備えて、Github Actions を使って Github 上でもビルドを行ってリポジトリからダウンロードできるようにしようと思いました。

そのため Github Actions の設定をあれこれ調べたのですが、プライベートリポジトリにしているせいで詰まった部分が結構ありましたので、備忘録代わりに調べたことをまとめます。

## 前提

ファイルの構成は次のとおり（主なファイルのみ列挙）で、リポジトリはプライベートリポジトリ。`contens/` ディレクトリに `.re` ファイルを保存しています。

```bash
.
├ README.md
├ Rakefile
├ catalog.yml
├ config-starter.yml
├ config.yml
├ contents/
├ workshop.pdf
```

## 結論

`.github/workflows/main.yml` を次のとおり設定し、環境変数 `PAT` に Personal access token（Scope は `repo` ）を設定すればビルドできます。

```yaml
on: [push]

jobs:
  review:
    runs-on: ubuntu-latest
    container: docker://kauplan/review2.5
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          repository: s-show/workshop_document
          token: ${{ secrets.PAT }}
          path: ./
      - name: Build pdf
        run: rake pdf
      - uses: actions/upload-artifact@v1
        with:
          name: Save PDF
          path: ./workshop.pdf
```

## 解説

`on: [push]` 
: アクション実行のタイミングを push 時に設定します。

`jobs.review:runs-on: ubuntu-latest`
: ワークフローを実行する仮想環境に Ubuntu の最新版を指定します。

`jobs.container: docker://kauplan/review2.5`
: Re:view Starter のビルドは Docker のコンテナを利用しているので、Github Actions でも Docker のコンテナを利用するための設定。コンテナには Re:view Starter の作者が作成したコンテナを指定します。

[kauplan/review2.5 - Docker Image | Docker Hub](https://hub.docker.com/r/kauplan/review2.5/)

`jobs.steps.name: Checkout`
: ジョブの命名。このジョブは、勉強会資料のリポジトリを Github Actions で使うためにチェックアウトするものなので「Checkout」としています。

`jobs.steps.name.uses: actions/checkout@v2`
: Github Actions の環境はリポジトリがチェックアウトされていない状態なので、そのままではリポジトリのデータにアクセスできません。そこで、公開アクションの `actions/checkout@v2` を使ってリポジトリをチェックアウトして `$GITHUB_WORKSPACE` の下に置くようにします。

[actions/checkout: Action for checking out a repo](https://github.com/actions/checkout)

`jobs.steps.name.with.repository: s-show/workshop_document`
: 勉強会資料のリポジトリをチェックアウトの対象に指定してます。

`jobs.steps.name.with.token: ${{ secrets.PAT}}`
: 勉強会資料のリポジトリはプライベートリポジトリなので、認証情報がなければ Github Actions はリポジトリにアクセスできない。そのため、ここで環境変数経由で認証情報を渡しています。

プライベートリポジトリを使う場合のコードは以下に掲載されています。

[actions/checkout: Action for checking out a repo](https://github.com/actions/checkout#Checkout-multiple-repos-private)

認証情報の生成は後で説明します。

`jobs.steps.name.with.path: ./`
: リポジトリのトップディレクトリを作業ディレクトリに指定しています。

`jobs.steps.name: Buid pdf` 
: ジョブの命名。このジョブは、PDFファイルを出力するジョブ。

`jobs.steps.run: rake pdf` 
: PDF ファイルをビルドするコマンド。Re:view Starter のユーザーズガイドに記載されている PDF 出力コマンドは `docker run --rm -v $PWD:/work -w /work kauplan/review2.5 rake pdf` であるが、最後の `rake pdf` だけで実行可能。

`jobs.steps.uses: actions/upload-artifact@v1`
: ビルドした PDF ファイルを保存するため、公開アクションの `upload-artifact@v1` を使用しています。

`jobs.steps.uses.with.path: ./workshop.pdf`
: トップディレクトリに `workshop.pdf` というファイル名で保存するよう設定しています。

## プライベートリポジトリにアクセスするための準備

プライベートリポジトリにアクセスするには認証情報が必要なので、認証情報を環境変数経由で Github Actions に渡すための設定を行います。

### Personal access token の生成

Personal access token の生成画面はユーザー設定画面にありますので、画面右上のユーザーアイコンの「Settings」を開いてから「Developer settings -> Personal access token -> generate new token」の順番で開いていきます。

生成ページを開いたら、`Note` に任意の名称を入力し、スコープに `repo` を指定して Personal access token を生成し、生成した Personal access token をコピーします。

### 環境変数の設定

環境変数はリポジトリ毎に設定するので、リポジトリの「Setting」を開いてから「Secrets -> New repository secret」の順番で開いていきます。

環境変数の設定画面を開いたら、 `Name` に `PAT` を、 `Value` に  `Personal access token` の値を貼り付けて保存します。

## デバッグ用の設定

デフォルト設定でもそこそこ詳しいログが保存されますが、さらに詳細なログが保存されても問題はないので、環境変数に次のペアを登録して詳細なログが保存されるように設定します。

`ACTIONS_STEP_DEBUG` → `true`

`ACTIONS_RUNNER_DEBUG` → `true`

[デバッグ ログを有効にする - GitHub Docs](https://docs.github.com/ja/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging)
