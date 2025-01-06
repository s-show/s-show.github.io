---
title: QMK API を使ってキーボードのリストを取得する方法
date: 2021-12-12T09:00:00+09:00
draft: false
tags: ['プログラミング', '自作キーボード']
---

## 前置き

自作キーボードのトラブルシューティングのための[問診票テンプレート](https://s-show.github.io/mon-shin-dialog-sample/)を作る時に、QMK Firmware リポジトリの `keyboards` ディレクトリにあるキーボードのリストを取得する方法を発見していました。

ネットを検索しても紹介されているページが見当たらないので、こちらで紹介します。

## 方法

`https://api.qmk.fm/v1/keyboards` にアクセスするとキーボードのリストが JSON 形式で返ってきますので、使用目的に合わせてテキスト処理をして使います。

```js
// コード例
fetch('https://api.qmk.fm/v1/keyboards')
  .then(response => {
    if (!response.ok) {
      throw new Error('Response not success.');
    }
      return response.text();
    }) 
    .then(data => {
      // `data` は CSV なので `split(',')` で配列に変換。
      const keyboardList = data.split(',');
      console.log(keyboardList);
    })
    .catch(error => console.error('There has been a problem with your fetch operation:', error));

> ["["0_sixty"", ""10bleoledhub"", ""1upkeyboards/1up60hse"", ""1upkeyboards/1up60hte"", ...
```

コード例2
```bash
curl https://api.qmk.fm/v1/keyboards | jq

[
  "0_sixty",
  "0_sixty/underglow",
  ...
  "zvecr/zv48/f401",
  "zvecr/zv48/f411"
]
```

---

参考情報
[qmk_api/docs/keyboard_api.md at master · qmk/qmk_api](https://github.com/qmk/qmk_api/blob/master/docs/keyboard_api.md)
[フェッチ API の使用 - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/Fetch_API/Using_Fetch)
