---
# type: docs 
title: REALFORCE R3S に USB Type-C コネクタを追加した話
date: 2024-09-08T23:10:15+09:00
featured: false
draft: false
comment: true
toc: false
tags: [備忘録,キーボード]
---

## 前置き

職場で [REALFORCE R3S（フルサイズ・日本語配列）](https://www.realforce.co.jp/products/series_master_r3s.html) を使っていますが、ケーブルがキーボードから直接伸びる形で長過ぎるため、思い切ってキーボードに USB Type-C のコネクタを追加して好きなケーブルを使えるようにしました。

出来上がりはかなり不恰好になりましたが、使える形になりましたので、備忘録として作業過程を残します。

なお、本記事を真似して問題が発生しても、こちらでは責任は負えませんので、その点はご了承ください。

## 使用した部品

以下の部品を使って USB Type-C のコネクタを作成しました。

<dl>
  <dt>USB Type-C レセプタクル</dt>
  <dd>
    <a href="https://www.amazon.co.jp/gp/product/B09VS7Z86D/">Amazon | オーディオファン 組込み用 USBレセプタクル USB-C用 メス 固定プレート付き USBコネクタ Cタイプ PCBボード M2ネジ付き 【4極専用 USB3以降は対応しません】 ブラック 2点セット | オーディオファン | USBアダプタ 通販</a>
  </dd>
  <dt>コネクタハウジング</dt>
  <dd>
    <a href="https://akizukidenshi.com/catalog/g/g112798/">PHコネクター ハウジング 5P PHR-5: ケーブル・コネクター 秋月電子通商-電子部品・ネット通販</a>
  </dd>
  <dt>コネクタコンタクト</dt>
  <dd>
    <a href="https://akizukidenshi.com/catalog/g/g112809/">PHコネクター コンタクト SPH-002T-P0.5L: ケーブル・コネクター 秋月電子通商-電子部品・ネット通販</a>
  </dd>
  <dt>ケーブル</dt>
  <dd>
    <a href="https://www.harmonet.co.jp/PDF/KYOWAcatalog-vol03.pdf">協和ハーモネット株式会社 耐熱ビニル絶縁電線 1007 AWG26 2mx7色</a>
  </dd>
</dl>

なお、上記の部品のうち、USB Type-C レセプタクル以外は[カホパーツセンター 九州唯一の電子パーツ専門店](https://www.kahoparts.co.jp/)というお店で購入しています。なので、お店の商品ページにリンクさせるべきとは思いますが、個別商品のページが用意されていないので、次善の策として秋月電子通商とメーカーのカタログにリンクしています。

## 作業の概要

作業の主な流れは次のとおりです。

- キーキャップを全て外す
- キーボードのカバーを外す
- 既存のケーブルと交換するための新しいケーブルを作成する
- 既存のケーブルをキーボードから取り外す
- 新しいケーブルを USB Type-C レセプタクルに半田付けする
- USB Type-C レセプタクルをキーボードに取り付ける

## 実際の作業

### キーキャップ取り外し

説明不要と思いますので手順は省略します。なお、外したキーキャップを洗浄してキーボードも掃除しておきましょう。

### カバー取り外し

まず、写真の箇所にあるネジを外します。これでカバーと基板が外れました。

{{< bsimage src="./image/IMG_0213.JPEG" title="" >}}

カバーは写真の箇所にツメで固定されていますので、写真の箇所にマイナスドライバーなどを差し込んで隙間を空けるとツメが外れてカバーが外れるようになります。なお、カバーは上側（ファンクンションキー側）を外してから下側（モディファイヤキー側）を外します。

### ハーネス作成

既存の直付け USB ケーブルは写真の箇所のコネクタに取り付けられていますので、まずこのコネクタを外して既存のケーブルをキーボードから取り出します。

{{< bsimage src="./image/IMG_0214.JPEG" title="コネクタ取り付け場所" >}}

それから新しいケーブルを作成しますが、既存のケーブルの各色の役割は以下のとおりです。

<dl>
  <dt>赤</dt>
  <dd>5V</dd>
  <dt>黒</dt>
  <dd>GND</dd>
  <dt>緑</dt>
  <dd>D+</dd>
  <dt>白</dt>
  <dd>D-</dd>
  <dt>青</dt>
  <dd>アース</dd>
</dl>

新旧のケーブルで色を変える必要性は乏しいので「赤・黒・白・緑」のケーブルを必要な長さにカットします。青のケーブルについては、私が使った USB レセプタクルにアース端子が用意されていないため、今回は省略しました。

ワイヤーをカットしたら、先端の皮膜をはがして PH コネクタのコンタクトを圧着します。圧着には [Amazon | ENGINEER エンジニア 精密圧着ペンチ PA-24 | 圧着ペンチ](https://www.amazon.co.jp/dp/B0BG5755B8/?th=1) を利用しています。圧着したらハウジングにセットした上で、反対側の皮膜もはがしてテスターで導通を確認します。

### レセプタクルへの半田付け

導通を確認できたらコネクタと反対側をレセプタクルに半田付けします。半田付けが終ったらレセプタクルに USB Type-C & Type-A ケーブルを差した上で、Type-A コネクタの端子と PH コネクタ間の導通を確認します。

{{< bsimage src="./image/IMG_0592.JPEG" title="ケーブル半田付け後" >}}

### レセプタクルのキーボードへの取り付け

これが一番苦労した作業でした。最初はレセプタクルを現在のケーブル取り出し口の近くに取り付けようとしました（以下の写真の赤枠の部分）。

{{< bsimage src="./image/IMG_0585.JPEG" title="ケーブル取り出しを断念した場所" >}}

しかし、ケースを大幅に加工しないと基板に当たってしまいケースが閉まらなくなってしまうことが判明しました。そこで、ケースの左側からケーブルを取り出すべく左側に取り付けようとしましたが、ケーブルの長さが足りませんでした。そこで、やむを得ず右側に取り付けることにしました（以下の写真の赤丸の部分）。

{{< bsimage src="./image/IMG_0590.JPEG" title="ケーブル取り出し場所">}}

レセプタクルを取り付けるには、ネジ穴をケースに空けた上で、USBケーブルの先端のカバーの大きさに合わせてケースを切り取る必要があります。ところが、ケーブルのカバーの大きさに合わせてケースを切り取ったらネジ穴を空けるスペースが無くなったーー正確にはネジ穴1つは空けられたものの、もう1つのネジ穴を空けるスペースが無くなったーーため、結局レセプタクルはネジと接着剤の併用で固定することになりました。

レセプタクルを取り付けたら、次はキーボードケースのカバーにも同様に切り取る必要があります。こちらについては、レセプタクルを固定しているネジと干渉しないことが必要になりますので、カバーより広い範囲を切り取ることになります。そうやってキーボードケースのカバーも切り取った結果が、下の写真の状況です。

{{< bsimage src="./image/IMG_0598.JPEG" title="ケース加工後">}}

## まとめ

出来上がりはかなり不細工ですが、これで既存のケーブルの取り回しに苦労しなくて済むようになりました。また、こういう既存品のカスタマイズは始めての取り組みでしたので、上手く出来るか不安でしたが、無事に動かせてホッとしています。 

本記事が何かの参考になれば幸いです。

（本記事は今回改造した REALFORCE R3S で執筆しました）
