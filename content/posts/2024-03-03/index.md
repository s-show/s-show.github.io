---
# type: docs 
title: Jspreadsheet のメモ
date: 2024-03-03T17:36:56+09:00
featured: false
draft: false
comment: true
toc: true
tags: [プログラミング]
---

## 前置き

自作のWebアプリで使っている [The javascript spreadsheet](https://bossanova.uk/jspreadsheet/v4/) について、備忘録としｔ

## どんなライブラリなのか？

Excel のようなスプレッドシートを Web 上に作成できる Javascript ライブラリです。Excel から直接値を貼り付けることもできますし、JSON からテーブルを作成することも可能です。また、入力値を制限することや、貼り付け前に貼り付けデータをチェックして不適切な値を除外することも可能な多機能なライブラリです。

## 導入方法

### NPM

以下のコマンドでインストールできます。

```bash
npm install jspreadsheet-ce
```

インストールしたら、`.js` ファイルの先頭に以下のコードを追加してモジュールを呼び出します。

```js
import jspreadsheet from 'jspreadsheet-ce';
```

### CDN

HTML ファイルの `<head>` タグに以下のコードを追加します。

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/jspreadsheet-ce/dist/jspreadsheet.min.css" type="text/css" />
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/jspreadsheet-ce/dist/index.min.js"></script>
```

## 使い方

HTML ファイルにスプレッドシートを表示する `<div>` タグを追加します。

```html
# index.html
<div id="sourceDataTable"></div>
```

それから `.js` ファイルで上記のタグの DOM 要素を使って表を初期化します。このとき、スプレッドシートに表示するデータを指定し、各種設定を行います。

```js
// 設定例
jspreadsheet(document.getElementById('convertedDataTable'), {
  data: initTableData,
  columns: columnsConfig,
  onbeforechange: beforechangeSourceTableTest,
  onbeforepaste: beforePasteConvertedTable,
  contextMenu: convertedTableContextMenuItems,
  onbeforedeletecolumn: beforeDeleteColumn,
  onbeforeinsertcolumn: beforeInsertColumn,
  text: text,
  freezeColumns: 2,
});
```

基本的な使い方は公式サイトの[Getting started with Jspreadsheet CE](https://bossanova.uk/jspreadsheet/v4/docs/getting-started)に掲載されていますので、本記事では、実際に使うにあたって色々調べた結果を備忘録としてまとめます。

## コンテキストメニューの設定

デフォルトの状態でコピー・貼り付けなどのメニューが用意されていますが、カスタマイズする場合、スプレッドシートのオプション項目の `contextMenu` で設定します。

例えば、コンテキストメニューで表示される機能を「行削除・コピー・貼り付け」の3つに限定する場合、次のコードとなります。なお、インラインでも書けると思いますが、さすがにインラインで書くには長いコードなので、定数を使っています。

```js
const sourceTableContextMenuItems = (obj, x, y, e) => {
  let items = [];
  if (obj.options.allowDeleteRow == true) {
    items.push({
      title: obj.options.text.deleteSelectedRows,
      onclick: () => {
        obj.deleteRow(obj.getSelectedRows().length ? undefined : parseInt(y));
      },
    });
    items.push({
      title: obj.options.text.paste,
      shortcut: 'Ctrl + V',
      onclick: () => {
        if (obj.selectedCell) {
          navigator.clipboard.readText().then((text) => {
            if (text) {
              jspreadsheet.current.paste(obj.selectedCell[0], obj.selectedCell[1], text);
            }
          });
        }
      },
    });
    items.push({
      title: obj.options.text.copy,
      shortcut: 'Ctrl + C',
      onclick: () => {
        obj.copy();
      },
    });
  }
  return items;
};

// コンテキストメニューの設定部分のみ表示しています（以下同様） 
jspreadsheet(document.getElementById('sourceDataTable'), {
  contextMenu: sourceTableContextMenuItems,
});
```

上のコードを解説しますと、コンテキストメニューに表示するメニューを格納する `items` 配列を用意し、そこにメニューを1つずつ格納していきます。各メニューをどうやって設定するかが問題になりますが、いくつかのメニューについては、[公式サイト](https://bossanova.uk/jspreadsheet/v4/examples/contextmenu)に設定が掲載されています。

しかし、公式サイトに載っていないメニューを設定しようとすると途端に難しくなります。ネットで検索して事例が見つかれば良いのですが、自分の検索方法が悪いのか事例が見つけられなかったので、かなり困りました。

ではどうやって解決したかと言いますと、Github の公式リポジトリの [ソースコード](https://github.com/jspreadsheet/ce/blob/master/src/index.js)の中にあるコンテキストメニューのコードを探し出し、そこから該当するメニューのコードをコピペして対処しました。例えば、貼り付けのコードは以下のリンク先にあり、コードは次のとおりです。

https://github.com/jspreadsheet/ce/blob/8e62e6016d364344aa5a735b918f155ad2afd10b/src/index.js#L7188-L7203

```js
// Paste
if (navigator && navigator.clipboard) {
  items.push({
    title: obj.options.text.paste,
    shortcut: 'Ctrl + V',
    onclick: function () {
      if (obj.selectedCell) {
        navigator.clipboard.readText().then(function (text) {
          if (text) {
            jexcel.current.paste(
              obj.selectedCell[0],
              obj.selectedCell[1],
              text,
            );
          }
        });
      }
    },
  });
}
```

このコードを元にして、以下のとおりコンテキストメニュー用のコードを書きました。上のライブラリのコードとほぼ同じコードで、`function` をアロー関数に置き換えています。

```js
items.push({
  title: obj.options.text.paste,
  shortcut: 'Ctrl + V',
  onclick: () => {
    if (obj.selectedCell) {
      navigator.clipboard.readText().then((text) => {
        if (text) {
          jspreadsheet.current.paste(
            obj.selectedCell[0],
            obj.selectedCell[1],
            text,
          );
        }
      });
    }
  },
});
```

コピーも貼り付けと同様に公式サイトに事例が掲載されていないため、貼り付けと同様に Github の[コード](https://github.com/jspreadsheet/ce/blob/8e62e6016d364344aa5a735b918f155ad2afd10b/src/index.js#L7179-L7186)を元に実装しました。

```js
// Copy
items.push({
  title: obj.options.text.copy,
  shortcut: 'Ctrl + C',
  onclick: function () {
    obj.copy(true);
  },
});
```

### メニューの日本語化

以下のコードのようにオブジェクト形式で「英語→日本語」の対応関係を定義した定数を用意して、その定数を表の初期化の際に `text` キーの値に指定すればOKです。

```js
const text = {
  deleteSelectedRows: '選択した行を削除',
  copy: '表の値をコピー',
  paste: '表に値を貼り付け',
};

jspreadsheet(document.getElementById('sourceDataTable'), {
  ~~~
  text: text,
  ~~~,
});
```

## テーブルのデータ削除

テーブルのデータを削除するには、テーブルのインスタンスから `setData()` メソッドを呼び出して空の配列を引数として渡します。

```js
/* テーブルの構造
| X     | Y    |
|-------|------|
| 110.1 | 51.1 |
| 120.2 | 52.2 |
| 130.3 | 53.3 |
*/
const sourceTable = jspreadsheet(document.getElementById('sourceDataTable'), {
  ~~~
});
const tableData = [[,]];
sourceTable.setData(tableData);
```

## 入力規則の設定

Excel の入力規則と同様にセルに入力できる値を制限することができます。この実装方法は2つあります。

### `columns` オプションを利用する

1つ目の実装方法は、`columns` オプションの `type` キーに値の型を設定するという方法です。例えば、2つの列をいずれも数値のみ入力できる列とする場合、`type` に `'numeric'` を設定します。

```js
const columnsConfig = [
  { type: 'numeric', title: 'X', name: 'x' },
  { type: 'numeric', title: 'Y', name: 'y' },
];

jspreadsheet(document.getElementById('sourceDataTable'), {
  columns: columnsConfig,
});
```

同様に、任意の列をテキストのみ受け付ける列にしたり、日付のみ受け付ける列にしたりできます。列に設定できる入力値の型は、公式サイトの [Column types](https://bossanova.uk/jspreadsheet/v4/examples/column-types) に掲載されています。

### `onbeforechange` イベントを利用する

2つ目の実装方法は、`onbeforechange` イベントのコールバック関数を使って入力しようとした値を入力前の段階でチェックして、入力して欲しくない値を入力させないという方法です。例えば、数値のみ入力させたいが、全角数値は半角数値に変換して受け入れるという条件にしたい場合、以下のように `onbeforechange` イベントのコールバック関数で入力値を処理することで、そうした複雑な条件の入力規則を設定できます。

入力値は `value` という変数で取得できますので、この変数をチェックして、全角・半角数値が入力されたなら半角数値に変換して受け入れて、全角・半角数値以外が入力されたなら `false` を返すことで、全角・半角数値のみ受け入れるという入力規則を実現できます。

なお、コールバック関数に渡す引数については、`value` しか利用しない場合でも `instance`、`cell`、`x`、`y` といった引数を渡す必要があるようです（渡さないとエラーになりました）。

```js
const beforechangeSourceTable = (instance, cell, x, y, value) => {
  if (isValidNumber(zen2han(value))) {
    return zen2han(value);
  } else {
    return '';
  }
};
const sourceTable = jspreadsheet(document.getElementById('sourceDataTable'), {
  data: initTableData,
  columns: columnsConfig,
  onbeforechange: beforechangeSourceTable,
  contextMenu: sourceTableContextMenuItems,
  onbeforedeletecolumn: beforeDeleteColumn,
  onbeforeinsertcolumn: beforeInsertColumn,
  onpaste: afterPaste,
  text: text,
  freezeColumns: 2,
});
```

info: 
なお、ここで登場する `isValidNumber()` と `zen2han()` 関数は自作関数で、前者は数値のように見える値は数値に変換して返すという関数で、後者は全角数値を半角数値に変換して返すという関数です。


## 表の編集禁止

結果を表示するだけで編集を予定していない表を作成したい場合、表を読み取り専用にすることができます。

方法は、表の初期化の際に設定する `columns` オプションに `readOnly` キーを追加して値を `true` にするというものです（公式サイトの[実装例](https://bossanova.uk/jspreadsheet/v4/examples/readonly)に掲載されています）。`columns` オプションで設定することから、読み取り専用にするか否か列単位で決めていきます。そのため、表全体を読み取り専用にする場合、全ての列を読み取り専用にする必要があります。

```js
const columnsConfig = [
  { type: 'numeric', title: 'X', width: 180, name: 'x', readOnly: true },
  { type: 'numeric', title: 'Y', width: 180, name: 'y', readOnly: true },
];
jspreadsheet(document.getElementById('sourceDataTable'), {
  columns: columnsConfig,
});
```

これで表が読み取り専用になるとともに、セルの値がグレーアウトして読み取り専用であることを示すようになります。

また、表の値を変更しても元に戻ってしまう状態にすることで、データの読み取りにしか使えない表を作ることもできます。

方法は、表の初期化の際に設定する `onbeforechange` イベントにコールバック関数を設定し、変更前のセルの値をその関数の戻り値にするというものです。ここで使用している `getValueFromCoords()` メソッドは、XYで指定されたセルの値を返すメソッドです。

```js
jspreadsheet(document.getElementById('sourceDataTable'), {
  onbeforechange: (instance, cell, x, y, value) => {
    return instance.jspreadsheet.getValueFromCoords(x, y);
  },
});
```

## 貼り付け無効化

表に値を貼り付けできないようにすることもできます。

方法は、表の初期化の際に設定する `onbeforepaste` イベントにコールバック関数を設定して、そのコールバック関数の戻り値を `false` にするというものです。公式サイトの[FAQ](https://bossanova.uk/jspreadsheet/v4/docs/most-common-questions-and-answers)に掲載されています。

```js
jspreadsheet(document.getElementById('spreadsheet'), {
  onbeforepaste: (instance, data, x, y) => {
    return false;
  }
});
```