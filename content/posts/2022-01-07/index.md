---
title: "PrusaSlicer/SuperSlicer で 一定のレイヤー毎に温度を変化させる方法"
date: 2022-01-07T21:41:06+09:00
draft: false
tags: [3Dプリンタ, 備忘録]
---

3D プリンタで新しいフィラメントを使う場合、最適な温度やリトラクト長を探し出す必要がありますが、「プリント→結果を確認→設定変更→プリント」という順番で調査すると時間がいくらあっても足りません。そのため、1回のプリントで様々な設定を試せると便利ということになります。

幸い、スライサー側の機能を使うことで、レイヤー高に応じて設定を変更することが可能となりますので、その方法を紹介します。

なお、スライサーによって設定方法だけでなくできることも違いますので、スライサー毎に説明します。ただし、結論を先取りしますと、PrusaSlicer/SuperSlicer よりも Cura の方が設定が簡単な上に出来ることも多いので、こういう処理を行う場合は Cura を使うか、G-Code を生成してくれるサービスを利用することをお勧めします。

## Cura の場合

まず、一度スライスしてからプレビュー画面に移動し、設定を変更するレイヤーの番号をメモします。ここでは45・90番目のレイヤーで温度を変更し、50番目のレイヤーでリトラクション長を変更するという前提とします。

まず、Cura のメニューの 「Extensions ｰ> Post Processing ｰ> Modify G-Code」を開きます。

それから、Add a script ボタンをクリックして「ChangeAtZ」を追加して `Trigger` を `layer No.` にして、`Change Layer` に設定を変更したいレイヤーの番号を指定します。そして、`Apply To` を `Target Layer + Subsequent Layers`にします。これで `layer No.` より上のレイヤーでは変更した設定が適用されるようになります。

例えば、最初は250度で印刷し、45番目のレイヤーから上は245度で印刷したいというときは `Change Extruder 1 Temp` にチェックを入れた上で、`Extruder 1 temp` に `245` を入力します。

{{< bsimage src="changeTemp.png" title="45番目のレイヤーから上の温度を240度に変更" >}}

また、最初はリトラクション長を 1mm で印刷し、50番目のレイヤーから上ではリトラクション長を 2mm にしたいというときは、`Change Retraction` にチェックを入れてから、`Change Retraction Length` にもチェックを入れ、`Retract Length` に `2` を入力します。

{{< bsimage src="changeRetracion.png" title="リトラクション長を2mmに変更" >}}

あとは、必要な分だけこの設定を繰り返します。

{{< bsimage src="changeTemp2.png" title="90番目のレイヤーから上の温度を230度に変更" >}}

## PrusaSlicer/SuperSlicer の場合

PrusaSlicer/SuperSlicer の場合、温度設定は変更できますが、リトラクション長の変更方法は見つけられていません。

一応、リトラクション長を変えつつ一度のプリントで9つのモデルを印刷するという<a href="https://forum.prusaprinters.org/forum/prusaslicer/use-height-range-modifier-for-specific-parameters/">方法</a>はあるようですが、思わぬ失敗で時間を無駄にしそうなので挑戦していません。

温度設定を変更する方法は、一度スライスしてからプレビュー画面に移動し、右側のスクロールバーを設定を変更するレイヤーに合わせます。

それから、そのレイヤーで右クリックして「カスタムG-Codeの追加」をクリックします。

{{< bsimage src="addCustomGcode.png" title="カスタムG-Codeの追加" >}}
{{< bsimage src="addCustomGcode_zoom.png" title="カスタムG-Codeの追加（拡大）" >}}

するとカスタム G-Code の入力画面が開きますので、以下のコードを追加します。なお、コードは上から順番に実行されるようです。

```
M106 S0;
M104 S240;
M109 S240;
M106 S255
```

M106 S0
: パーツ冷却ファンをストップさせるコマンドです。これがないと、エクストルーダーの温度が設定温度になるまでの間、同じ個所を冷やし続けることになります。

M104 S240
: エクストルーダーの温度が240度に設定するコマンドです。設定温度に到達する前に次のコマンドに移ります。

M109 S240
: エクストルーダーの温度が240度になるまで待機するというコマンドです

M106 S255
: パーツ冷却ファンの回転数を元に戻す（ここでは全開にする前提）コマンドです。これがないと、パーツ冷却ファンがストップしたままとなります。

以上で PlusaSlicer/SuperSlicer を使ってレイヤー高に応じて設定を変える方法を紹介しましたが、正直な所、Cura と比較して明らかに面倒になります。

なので、もっと楽をする方法を紹介します。

## ウェブページで G-Code を生成する方法

YouTube で3Dプリンタの情報を中心に色々な解説動画を出している Teaching Tech が 3Dプリンタのキャリブレーションテクニックなどをまとめたページを作成しています。

[Teaching Tech 3D Printer Calibration](https://teachingtechyt.github.io/calibration.html)

こちらでは温度調整やリトラクト長の調整のための G-Code を生成することが出来ますので、こちらで G-Code を生成して印刷するとスライサーの設定をしなくても必要な G-Code が作れます。

## まとめ

新しいフィラメントを使う場合、温度設定やリトラクション長などは試行錯誤して最適値を割り出す必要がありますので、上記の方法を利用すると最適値の探索が少し楽になります。

一度最適値を割り出してしまえば、その設定値はずっと使えますので、上記の方法が何かの役に立てば幸いです。