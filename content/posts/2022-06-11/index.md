---
title: "html-include の使い方"
date: 2022-06-11T16:09:50+09:00
draft: false
---

## 前置き

自作キーボードのコミュニティで使用している質問用フォームを管理していますが、1つのページに全ての質問を載せる形から、問題の内容に応じて質問を分けるようにしました。

この改修により、管理するページ数が1から6に増え、そのうち5つのページでヘッダー等が共通していましたので、共通部分を切り出す方法を探したところ、[html-includes - npm](https://www.npmjs.com/package/html-includes) というプラグインがちょうど良かったため、早速使うことにしました。

このプラグインの解説をした日本語ページが見当たらなかったので、備忘録を兼ねて簡単な使い方を説明します。

## プラグインの概要

あるHTMLファイルに別のHTMLファイルを挿入してくれるプラグインです。各ページに共通する部分を別ファイルに切り出して、それをビルドして一つのファイルに統合することができるようになります。


## インストール方法

npm でプラグインをインストールします。

```bash
npm i --save-dev html-includes
```

それから `package.json` に次の設定を追加すると、 `npm run compile` コマンドでビルドできるようになります。

```json
"scripts": {
  "compile": "html-includes --src src --dest dist",
  "compile:watch": "html-includes --src src --dest dist --watch"
},
```

`html-includes` のオプションは次のとおりです。

`-src src`
: 統合する html ファイルが保存されているディレクトリを指定する。

`-dest dist`
: 統合した html ファイルを保存するディレクトリを指定する。

`--watch`
: ファイルが変更されたら自動的にビルドする。

## 使い方

大まかな手順は次のとおりです。

- 共通部分を読み込む側の html ファイルに `${require('読み込みたいファイルのパス')}` を記述
- 上で説明した `-src src` で指定したディレクトリに共通部分を切り出した html ファイルを保存
- `npm run compile` でビルドする

```bash
# ファイル構成
src/
└── html
    ├── common
    │   ├── _firmwareInfo.html
    │   ├── _footer.html
    │   ├── _head.html
    │   ├── _header.html
    │   ├── _microcomputerInfo.html
    │   ├── _otherInfo.html
    │   ├── _resultForm.html
    │   ├── _tailOfBodyTag.html
    │   └── _testMicrocomputerOnly.html
    ├── BLEProblem.html
    ├── buildProblem.html
    ├── designProblem.html
    ├── firmwareProblem.html
    ├── index.html
    ├── memo.html
    └── otherProblem.html

 dist/
├── BLEProblem.html
├── buildProblem.html
├── designProblem.html
├── firmwareProblem.html
├── index.html
└── otherProblem.html
```

### 読み込む側の html ファイルの設定

html ファイルに `${require('/common/_microcomputerInfo.html')}` と追加すると、その部分に `/common/_microcomputerInfo.html` の内容が追加されます。

```html
# src/html/buildProblem.html
<div class="border rounded shadow-sm m-3 p-3 bg-white">
  ${require('/common/_microcomputerInfo.html')}
</div>
```

```html
# /common/_microcomputerInfo.html
  <h2 id="microcomputerInfomationTitle">マイコンの情報</h2>
  <div class="form-group p-2" id="microcomputerInfomation">
    <label id="labelMicrocomputerInfo">マイコンの種類</label>
    <div class="form-check">
      <input class="form-check-input" type="radio" name="microcontroller" id="promicro(atmega32u4)" value="Pro Micro(ATmega32U4)">
      <label id="labelProMicro(ATMega32U4)" class="form-check-label" for="promicro(atmega32u4)">Pro Micro(ATmega32U4)</label>
    </div>
    <div class="form-check">
      <input class="form-check-input" type="radio" name="microcontroller" id="promicro(RP2040)" value="Pro Micro(RP2040)">
      <label id="labelProMicro(RP2040)" class="form-check-label" for="promicro(RP2040)">Pro Micro(RP2040)</label>
    </div>
  </div>
```

```html
# dist/buildProblem.html
<div class="border rounded shadow-sm m-3 p-3 bg-white">
  <h2 id="microcomputerInfomationTitle">マイコンの情報</h2>
  <div class="form-group p-2" id="microcomputerInfomation">
    <label id="labelMicrocomputerInfo">マイコンの種類</label>
    <div class="form-check">
      <input class="form-check-input" type="radio" name="microcontroller" id="promicro(atmega32u4)" value="Pro Micro(ATmega32U4)">
      <label id="labelProMicro(ATMega32U4)" class="form-check-label" for="promicro(atmega32u4)">Pro Micro(ATmega32U4)</label>
    </div>
    <div class="form-check">
      <input class="form-check-input" type="radio" name="microcontroller" id="promicro(RP2040)" value="Pro Micro(RP2040)">
      <label id="labelProMicro(RP2040)" class="form-check-label" for="promicro(RP2040)">Pro Micro(RP2040)</label>
    </div>
  </div>
</div>
```

### 読み込まれる側の html ファイルの設定

読み込まれる側の html ファイルに必要な設定はありませんが、読み込まれる html ファイルのファイル名の一文字目を `_` にすると、ビルド時に読み込んだファイルが `dist` ディレクトリにコピーされなくなります。

また、読み込まれる側の html ファイルに Javascript 式に似た `<p>Main content ${props.foo}</p>` のような設定を追加しておくと、読み込む側のファイルで `${require('./_main.html') foo="and you can also pass props"}` とすることで文字列を受渡しできるようになります。ページタイトルのように共通部分の一部のみ変更する必要がある場合に役に立ちます。

```html
# src/html/buildProblem.html
<head>
  ${require('/common/_head.html') pageTitle="組み立てに関する問題"}
</head>
```

```html
# common_head.html
<meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

  <!-- Font Awesome -->
  <link
  href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"
  rel="stylesheet"
  />
  <!-- Google Fonts -->
  <link
  href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700&display=swap"
  rel="stylesheet"
  />
  <!-- MDB -->
  <link
  href="https://cdnjs.cloudflare.com/ajax/libs/mdb-ui-kit/4.0.0/mdb.min.css"
  rel="stylesheet"
  />

  <link rel="icon" href="image/favicon.ico">

  <title>問診票テンプレート - ${props.pageTitle}</title>
```

```html
# dist/buildProblem.html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

  <!-- Font Awesome -->
  <link
  href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"
  rel="stylesheet"
  />
  <!-- Google Fonts -->
  <link
  href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700&display=swap"
  rel="stylesheet"
  />
  <!-- MDB -->
  <link
  href="https://cdnjs.cloudflare.com/ajax/libs/mdb-ui-kit/4.0.0/mdb.min.css"
  rel="stylesheet"
  />

  <link rel="icon" href="image/favicon.ico">

  <title>問診票テンプレート - 組み立てに関する問題</title>
</head>
```