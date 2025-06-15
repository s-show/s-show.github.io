---
# type: docs 
title: ウェブページを印刷するときにヘッダー・フッターを設定する方法
date: '2025-06-15T00:00:00+09:00'
draft: false
featured: false
comment: true
toc: true
tags: [html, css, javascript, プログラミング]
archives: 2025/06
codeMaxLines: 10
---

## 前置き

職場で使える簡易な写真帳作成ツールが欲しかったので、PC に保存している写真を読み込んで写真帳の形に整えるウェブページを作成しました。リポジトリは [s-show/photo-book](https://github.com/s-show/photo-book) です。

このウェブページには Word や Excel へのエクスポート機能を付けましたので、エクスポートしたファイルの印刷設定は Word や Excel の機能で調整できます。しかし、ブラウザの印刷機能では細かい調整ができないため、印刷を考慮した設定が必要になります。特に、ヘッダー・フッターはブラウザで設定できないため、ウェブページに実装する必要があります。そこで、任意の文字列をヘッダー・フッターに指定する機能を実装しましたので、その際に調べたことを備忘録としてまとめます。

## 実装

基本的な実装は [CSS を使用して印刷するときにウェブページの余白にコンテンツを追加する](https://developer.chrome.com/blog/print-margins?hl=ja) を参考にしています。ただ、このページでは、`string-set` プロパティで `<h1>` タグのコンテンツを取得して余白に表示していますが、`string-set` を使おうとすると Neovim の LSP が `Unknown property: 'string-set' [unknownProperties]` という警告を表示[^1]し、`<h1>` タグのコンテンツを取得できなかったので、違う方法にしました。

[^1]: [CSS Generated Content for Paged Media Module](https://www.w3.org/TR/css-gcpm-3/#setting-named-strings-the-string-set-pro) を見ると `string-set` プロパティはまだ "Working Draft" の段階のようですので、LSP が警告を出したのかと思います。

それでは具体的な実装を説明しますが、まず、`@page` アットルールを使って印刷用の CSS を設定します。

```css
@page {
  size: A4;
  margin: 20mm;
}

@top-center {
  content: var(--headerText, "photo-book");
  margin-top: 10px;
  font-size: 16pt;
}
@bottom-center {
  content: counter(page) "/"  counter(pages);
}
```

ここでは `@top-center` アットルールを使ってページ上部中央をヘッダーとして使うための設定を、`@bottom-center` アットルールを使ってページ下部中央をヘッダーとして使うための設定を行っています。

また、`@top-center` の `content` を `var(--headerText, "photo-book")` とすることで表示する文字列を自由に指定できるようにしています（デフォルト値は "photo-book"） 。そして、`@bottom-center` の `content` に `counter(page)` を使ってページ番号を、`counter(pages)` を使って総ページ数を表示しています。これにより、フッター部分に「1/3」の形でページ番号が表示されます。

CSS の設定は以上で、次に `@top-center { content: }` の `var()` の引数の `--headerText` を定義するため、javascript でコードを以下のとおり設定します。

```js
// `"タイトル文字列"` の部分は、実際のコードでは <input> の value にしています。
document.documentElement.style.setProperty('--headerText', `"タイトル文字列"`)
```

これで `<html>` 要素の `style` プロパティに `--headerText: "タイトル文字列"` がセットされ、そのプロパティの値を CSS の `var(-headerText)` で取得できるようになりましたので、`タイトル文字列` という文字列が各ページ上部の中央に表示されます。

これで印刷時にヘッダー・フッターを表示することができるようになりました。

ヘッダー・フッター以外にも応用できるテクニックだと思いますので、この記事が何かの参考になれば幸いです。

（↓ 実際に設定したヘッダーとフッター）

{{< bsimage src="./image/screenshot1.png" title="" >}}
{{< bsimage src="./image/screenshot2.png" title="" >}}
