---
# type: docs 
title: PDFファイルの切り出しと圧縮方法
date: 2023-03-15T23:08:57+09:00
featured: false
draft: false
comment: true
toc: true
tags: [備忘録]
images: []
---

## 前置き

職場内研修の資料を [Re:VIEW - Digital Publishing System for Books and eBooks](https://reviewml.org/ja/) を使って作成していますが、ページが増えて出力した PDF の容量が職場のメールの容量制限に引っかかるようになりました。そこで PDF の切り出しツールと圧縮ツールを探したら以下のツールが見つかりましたので、備忘録を兼ねてツールの紹介と簡単な使い方をまとめます。


## 環境

OS
: Windows11 Pro 22H2

WSL
: 1.1.3.0

OS on WSL
: Ubuntu-20.04


## 使用するツール

PDF の切り出しは [pdftk-java / pdftk-java · GitLab](https://gitlab.com/pdftk-java/pdftk) を使用し、圧縮は [Ghostscript](https://www.ghostscript.com/) を使用しています。それぞれのツールは次のコマンドでインストールしています。

```bash
sudo apt-get --yes install pdftk 
sudo apt install ghostscript
```


## 切り出し方法

次のコマンドで PDF ファイルを切り出します。このコマンドは `foo-bar.pdf` の1ページから12ページを切り出して `foo.pdf` ファイルとして保存しています。


```bash
pdftk foo-bar.pdf cat 1-12 output foo.pdf
```

{{% alert info %}}
ここで指定するページ数は、ファイルの1ページ目からの通し番号を指定する必要があります。以下のスクリーンショットにあるページを切り出したい場合、`140` ではなく `148` を指定する必要があります。
{{% /alert %}}

{{< bsimage src="Untitled.png" title="PDFファイルのページ数の見本" >}}


## 圧縮方法

次のコマンドを実行して PDF ファイルを圧縮します。このコマンドは `input.pdf` ファイルを圧縮して `output.pdf` として出力します。`-dPDFSETTINGS=/printer` の `printer` は 300dpi で出力するというオプションで、これを `screen` にすると 72dpi になります。

```bash
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/printer -dNOPAUSE -dQUIET -dBATCH -sOutputFile=output.pdf input.pdf
```

ちなみに、`-dPDFSETTINGS=/printer` と `-dPDFSETTINGS=/screen` のオプションの違いによるファイルサイズの差は次のとおりです。 

元ファイル
: 10.79 MB

`-dPDFSETTINGS=/ptinter`
: 4.46 MB

`-dPDFSETTINGS=/screen`
: 1.36 MB

## 参考にしたサイト

- [Split a PDF in two](https://stackoverflow.com/questions/17776582/split-a-pdf-in-two/17776583#17776583)
- [PDFtk - The PDF Toolkit](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)
- [Reduce PDF File Size in Linux | DigitalOcean](https://www.digitalocean.com/community/tutorials/reduce-pdf-file-size-in-linux)
- [pdftk の基本的な使い方 - Qiita](https://qiita.com/masashi_mizuno_chestnut/items/14c0b877bed7fee0877b)
