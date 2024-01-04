---
# type: docs 
title: 3Dプリンタのステッピングモーターの配線について
date: 2023-04-07T22:13:07+09:00
featured: false
draft: false
comment: true
toc: true
tags: [3Dプリンタ, 備忘録]
---

## 前置き

Ender 3 Pro で Voron Trident の印刷パーツを印刷していたら突然印刷ができなくなり、原因を調べたらモーターがガタガタと振動して正常に回転していませんでした。

そこでモーターを買い替えて交換したのですが、新しいモーターを動かすまでにあれこれ調べる必要に迫られたため、その時調べたことなどを備忘録として残します。


## 試行錯誤の経緯

### ステッピングモーターの結線

今回の購入したステッピングモーターは Amazon で購入したものですが、商品ページに結線情報は掲載されていませんでした。ネットで検索したら該当しそうな情報が見つかりましたが、結論から言うとその情報は間違っていました。

そこでステッピングモーターについて調べ直したのですが、その過程で、ステッピングモーターの4本の配線は、以下の図のとおり2本ずつのペアで「A相、B相」を構成していることに気付きました。なお、以下の図は、オリエンタルモーター社の[「テクニカルマニュアル ステッピングモーター編」](https://www.orientalmotor.co.jp/tech/technicalmanual/stepping/)の50ページに掲載されていたものです。

{{< bsimage src="wiring_diagram_in_motor.png" title="ステッピングモーターの内部配線" >}}

そして、モーター内部で図のとおり繋がっているのであれば、テスターを順番に当てていけば内部で繋がっているピン同士を確認できることに気付きました。

実施にテスターを当てて調べたところ、内部で繋がっているピンの組み合わせを以下の写真のとおり特定することができました。

{{< bsimage src="wiring_diagram_photo.jpg" title="モーターの結線状況">}}


### SKR 3 ez の結線

SKR 3 ez のハードウェア情報は [SKR-3/Hardware (SKR 3 EZ) at master · bigtreetech/SKR-3](https://github.com/bigtreetech/SKR-3/tree/master/Hardware%20(SKR%203%20EZ)) で公開されていますが、最初、[ピンの配置図](https://github.com/bigtreetech/SKR-3/blob/master/Hardware%20(SKR%203%20EZ)/BIGTREETECH%20SKR%203%20EZ%20V1.0-PIN.pdf)に記載された「2B 2A 1A 1B」の組み合わせ方が分かりませんでした。

{{< bsimage src="skr3ez_pinout.png" title="SKR 3 ez のピン配置図">}}

「2B 1B」がB相に、「2A 1A」がA相になるのかと思いましたが違っており、「2B 2A」がA相に、「1A 1B」がB相になるという組み合わせでもありませんでした。組み合わせを間違えた場合、ガタガタと振動するだけならまだしも、場合によっては `ShortToGND_A!` というエラーが発生して強制シャットダウンされることもありました。

そのため、あらためて SKR 3 ez の回路図を確認していると、ピンの配置図の「2B 2A 1A 1B」はモータードライバーの出力ピンの名称と一致していないことに気付きました。

{{< bsimage src="skr3_ez_scheme.png" title="SKR 3 ez の回路図">}}

これで正しい配線方法を特定することができるようになりましたので、以下の図のとおり配線して動かせるようになりました。なお、中継基板を挟んだ結線の線の色は、実際のケーブルの色に合わせています。

{{< bsimage src="wiring_diagram.png" title="最終的な配線方法">}}

ちなみに、上の図ではモータードライバーの「B2 B2」にモーターのA相を、「A2 A1」にモーターのB相を割り当てていますが、反対にしても動くと思います。私の場合、中継基板を挟んで同じ線同士を接続しておけば、何らかのトラブル対応でコネクタからケーブルを取り外した時に戻しやすくなると考えてこのように配線しています。

### Klipper の設定

こちらは簡単で、SKR 3 ez の回路図に記載された XYZ 軸とエクストルーダーの `DIR` `STEP` `EN` `UART` のピンの指定に合わせて `printer.cfg` を指定するだけです。 

{{< bsimage src="skr3_ez_motor-driver_scheme.png" title="SKR 3 ez の回路図">}}

```
[extruder]
step_pin: !PD15
dir_pin: !PD14
enable_pin: !PC7

[tmc2130 extruder]
cs_pin: PC6
spi_software_miso_pin: PE15
spi_software_mosi_pin: PE13
spi_software_sclk_pin: PE14
run_current: 0.7
```
