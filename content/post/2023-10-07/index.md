---
# type: docs 
title: leaflet 覚書
date: 2023-10-07T00:41:37+09:00
featured: false
draft: false
comment: true
toc: false
tags: [備忘録,プログラミング]
archives: 2023/10
---

## 前置き

仕事で「XY座標を使ってオンライン地図に土地の境界点を示すアプリが欲しい」と思って自作したのですが、アプリ制作で使った [Leaflet - a JavaScript library for interactive maps](https://leafletjs.com/) について、メモしておかないと忘れそうな点がありましたので、備忘録としてまとめます。

なお、作成したアプリは [座標の地図表示と座標・緯度経度の変換](https://kankodori-blog.com/interchangeXYandBL/) というものです。

## 地図に追加したマーカーの削除

leaflet を使って地図にマーカーを追加する方法は検索すればいくつも見つかりますが、追加したマーカーをまとめて削除する方法が見つけられませんでした。

そこで色々調べて、マーカーをまとめて削除する方法を何とか編み出しました。

まず、leaflet では、追加したマーカーは layer として `map` インスタンスに追加されます。`map` インスタンスにはマーカー以外のレイヤーも存在していますが、どのレイヤーがマーカーのレイヤーなのかを特定できれば、そのレイヤーを削除することでマーカーを削除できます。

私が調べた限りでは、マーカーのレイヤーのプロパティには `_icon` というキーが追加され、このキーに対応する値にマーカーとして使っている画像ファイルのパスが格納されるようです。そのため、マーカーをまとめて削除する場合、`Map` クラスの `eachLayer()` メソッドを使って `map` インスタンスに存在するレイヤーを順番に調べて、プロパティに `_icon` キーが存在していたら削除するという方法が使えるようです。

具体的なコードは次のとおりです。マーカーを全削除するボタンをクリックするという前提です。

```javascript
// マップの初期化コード（必要最低限の箇所だけ表示）
// 緯度経度の場所は日本緯度経度原点
let map = L.map('map',
  {
    renderer: L.canvas(),
    preferCanvas: true
  }).setView([35.6580992222, 139.7413574722], 15);

// マーカー全削除のコード
document.getElementById('removeMarkerBtn').addEventListener('click', (e) => {
  map.eachLayer((layer) => {
    if (layer._icon != undefined) {
      map.removeLayer(layer);
    }
  })
  e.preventDefault();
})
```

### レイヤーを削除せずにマーカーを削除する方法

ちなみに、レイヤーを削除せずにマーカーを削除することも可能です。

地図に追加したマーカーは、後述する線と異なりDOMツリーに追加されますので、マーカーに特徴的なセレクタと `querySelectorAll()` メソッドでまとめて取得できます。私が調べた限りでは、セレクタに `'.leaflet-marker-pane>img'` を指定すればOKのようですので、次のコードでマーカーをまとめて削除できます。

```javascript
let markers = document.querySelectorAll('.leaflet-marker-pane>img');
markers.forEach((marker) => marker.remove());
```


## 地図に追加した線の削除

次は地図に追加した線を削除する方法ですが、DOMツリーで線に該当するDOMを見つけられませんでしたので、線のレイヤーを削除する方法で対処しました。

方法は前述のマーカーの一括削除と同じで、`map` インスタンスに存在するレイヤーを順番に調べて、線のレイヤーが見つかれば削除するという方法です。

私が調べた限りでは、線のレイヤーのプロパティには `options.color` というキーが追加され、このキーの値に線の色が格納されるようですので、このキーを使って次のコードで処理するようにしました。

```javascript
// 線の削除コード
document.getElementById('removeMarkerBtn').addEventListener('click', (e) => {
  map.eachLayer((layer) => {
    if (layer.options.color != undefined) {
      map.removeLayer(layer);
    }
  })
  e.preventDefault();
})
```


## 地図に追加した円の削除

(2023年11月2日追加)

地図に追加した円を削除する方法ですが、こちらも線と同様にDOMツリーで該当するDOMを見つけられませんでしたので、線と同様にレイヤーを削除する方法で対処しました。

私が調べた限りでは、線のレイヤーのプロパティには円の半径を格納する `layer._mRadius` というキーが追加されますので、このキーを使って次のコードで処理するようにしました。

```javascript
// 円の削除コード
document.getElementById('removeMarkerBtn').addEventListener('click', (e) => {
  map.eachLayer((layer) => {
    if (layer._mRadius != undefined) {
      map.removeLayer(layer);
    }
  })
  e.preventDefault();
})
```

## 追加した図形をクリックして削除する設定

2023年11月2日追加

地図に追加したアイコンや線について、クリックしたら削除されるという設定です。

設定方法は、`on()` メソッドでアイコンや線にクリック時に実行されるイベントリスナーを登録するというものです。`addEventListener()` メソッドで DOM に処理を追加するのと同じ感覚で設定できます。具体的なコードは次のとおりです。

```javascript
// マーカーを地図に追加するときにクリック時の処理を追加し、その中でそのマーカー自身を削除する処理を追加。
L.marker([Number(data[0]), Number(data[1])], { icon: iconColor }).addTo(map).on('click', (e) => {
  e.target.remove()
});
// 線を地図に追加するときにクリック時の処理を追加し、その中でその線自身を削除する処理を追加。
L.polyline(convertedData, { color: lineColor.value}).addTo(map).on('click', (e) => {
  e.target.remove()
});
// 円を地図に追加するときにクリック時の処理を追加し、その中でその円自身を削除する処理を追加。
L.circle([Number(latitude), Number(longitude)], circleOption).addTo(map).on('click', (e) => {
  e.target.remove();
})
// 地図に追加した円をいったん変数に格納し、その変数にクリック時の処理を追加する方法もOK。
let circle = L.circle([Number(latitude), Number(longitude)], circleOption).addTo(map);
circle.on('click', (e) => {
  e.target.remove();
})
```

注意点は、マーカーや線はイベントバブリングがデフォルトでオフになっていますが、円はデフォルトでオンになっています。そのため、イベントがバブリングすると困る場合、円を追加するときに `bubblingMouseEvents` オプションを `false` にします。
