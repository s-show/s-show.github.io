---
# type: docs 
title: Raspberry pi pico と XIAO RP2040 を使って温度や Input Shaper を計測する方法
date: 2023-02-05T00:00:00+09:00
draft: false
comment: true
toc: true
categories: []
tags: [3Dプリンタ, Klipper, 備忘録]
archives: 2023/02
---

{{<toc>}}

## 長い前置き

Prusa MK3S+ で印刷中にベッドの温度が急激に低下し、場合によっては氷点下まで下がってしまいプリンタが止まってしまうという症状が年末から発生していました。

Discord の Klipper_jp でのアドバイスを基にベッドを手でグイグイ動かすと温度が急低下する瞬間があったため、サーミスタの断線が原因だと判断してサーミスタを交換しました。ところが、今度はノズルとベッドが設定温度に到達してホーミング＆メッシュベッドレベリングが始まると、ベッドのヒーターの出力が100%なのにベッドの温度が下がり続けるという不具合が起きました。この不具合の恐ろしいところは、Fluidd の操作画面に表示される温度は下がり続けているのに非接触型温度計で測定する温度は上がっていることで、これでは火事になりかねません。

そこで、Raspberry pi pico をセカンド MCU にして、ベッドの温度を einsy ボードではなく Raspberry pi pico で計測して同じ問題が発生するか問題が解消するか確かめることにしました。すると、「印刷が始まったら出力100％なのに温度が低下し続けて92℃まで下がる（ここで印刷を手動中止）」という状態だったのが、印刷が始まって96.5℃ぐらいまで下がったところで温度上昇に転じて100℃前後をキープできるようになりました（それでも室温が10℃以下だとベッドの加熱が追い付かなくて `Heater heater_bed not heating at expected rate` エラーになることはありますが）。

このように Raspberry pi pico をセカンド MCU にする方法は Input Shaper の測定で紹介されていますが、温度計測に応用した記事は見当たらなかった（そもそもマザーボードを買い替えろという指摘はいったん脇に置いといて）ので、手順などをまとめたいと思います。

また、Raspberry pi pico と同じ RP2040 マイコンを使い、サイズが Raspberry pi pico の約3分の1程度[^size]の Seeed Studio XIAO RP2040 を使って Input Shaper を計測することにも成功しましたので、この方法も紹介します。 

[^size]: Raspberry pi pico のサイズは 21 x 51mmで、XIAO RP2040 のサイズは 20 x 17.5mm です。

## Raspberry pi Pico を使った温度測定

### BOM

1. Raspberry pi pico
1. サーミスタ（104NT-4-R025H42G）
1. ユニバーサル基板（ブレッドボード配線パターンタイプ）
1. XHコネクタ（2ピン）
1. 電解コンデンサ（10μF）
1. 抵抗（4.7kΩ と 0Ω）

ユニバーサル基板は、配線のはんだ付けを少しでも楽にするために[片面ガラス・ユニバーサル基板（ブレッドボード配線パターンタイプ）: パーツ一般 秋月電子通商-電子部品・ネット通販](https://akizukidenshi.com/catalog/g/gP-04303/)を使いました。

0Ωの抵抗は、配線の手間を減らすためにワイヤー代わりに使ったものです。

### 手順

#### Klipper のインストール

Raspberry pi pico をセカンド MCU にするには Klipper ファームウェアを書き込む必要がありますので、Klipper をインストールして3Dプリンタを制御している Raspberry pi 上でファームウェアを作成します。なお、ファームウェアの作成には、Klipper と関連ツールのインストール・アップデートを簡単にするツールである [th33xitus/kiauh: Klipper Installation And Update Helper](https://github.com/th33xitus/kiauh) を使います。

それでは作業手順ですが、まず Raspberry pi に SSH で接続して `kiauh/kiauh.sh` コマンドで KIAUH を起動し、メニューの 4) [Advanced] を選択します。

```
/=======================================================\
|     ~~~~~~~~~~~~~~~~~ [ KIAUH ] ~~~~~~~~~~~~~~~~~     |
|        Klipper Installation And Update Helper         |
|     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     |
\=======================================================/
/=======================================================\
|     ~~~~~~~~~~~~~~~ [ Main Menu ] ~~~~~~~~~~~~~~~     |
|-------------------------------------------------------|
|  0) [Log-Upload]   |       Klipper: Installed: 1      |
|                    |          Repo: Klipper3d/klipper |
|  1) [Install]      |                                  |
|  2) [Update]       |     Moonraker: Installed: 1      |
|  3) [Remove]       |                                  |
|  4) [Advanced]     |      Mainsail: Installed!        |
|                    |        Fluidd: Installed!        |
|                    | KlipperScreen: Not installed!    |
|  6) [Settings]     |  Telegram Bot: Not installed!    |
|                    |         Obico: Not installed!    |
|                    |                                  |
|  v5.0.0-14         |     Octoprint: Not installed!    |
|-------------------------------------------------------|
|                        Q) Quit                        |
\=======================================================/
####### Perform action: 4
```

それから Firmware メニューの 2) [Build only] を選択します。

```
/=======================================================\
|     ~~~~~~~~~~~~~~~~~ [ KIAUH ] ~~~~~~~~~~~~~~~~~     |
|        Klipper Installation And Update Helper         |
|     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     |
\=======================================================/
/=======================================================\
|     ~~~~~~~~~~~~~ [ Advanced Menu ] ~~~~~~~~~~~~~     |
|-------------------------------------------------------|
| Klipper & API:          | Mainsail:                   |
|  1) [Rollback]          |  6) [Theme installer]       |
|                         |                             |
| Firmware:               | System:                     |
|  2) [Build only]        |  7) [Change hostname]       |
|  3) [Flash only]        |                             |
|  4) [Build + Flash]     | Extras:                     |
|  5) [Get MCU ID]        |  8) [G-Code Shell Command]  |

|-------------------------------------------------------|
|                       B) « Back                       |
\=======================================================/
####### Perform action: 2
```

するとビルドオプションの設定画面が表示されますので Micro-controller Architecture を選択して Raspberry pi RP2040 を選択します。

{{< bsimage src="klipper_firmware_1.png" title="ビルドオプションの設定画面" >}}
{{< bsimage src="klipper_firmware_2.png" title="マイコンのアーキテクチャ選択画面" >}}

マイコンのアーキテクチャに Raspberry pi RP2040 が選択されると、Bootloader offset と Communication interface も自動的に設定されますので、`Q` `Y` とタイプして設定を保存して画面を閉じます。

{{< bsimage src="klipper_firmware_3.png" title="設定後の画面" >}}

これでファームウェアのビルドが始まりますので、終わるまでしばし待ちます。ビルドが終わるとファームウェアが `~/klipper/out/klipper.uf2` として保存されていますので、手元のパソコンにコピーします。私の場合、手元のパソコンで `scp pi@192.168.1.25:~/klipper/out/klipper.uf2 ~/` コマンドを実行してコピーしました。

Raspberry pi pico へのファームウェア書き込みは、まず、BOOTSEL ボタンを押しながら pico をパソコンに接続します。すると、pico がマスストレージとして認識されます。

{{< bsimage src="write_uf2_pico.png" title="マスストレージとして認識された Raspberry pi pico" >}}

ここに先程 Raspberry pi からコピーしてきた `klipper.uf2` をコピーします。これでファームウェアの書き込みが自動的に始まり、書き込みが完了すると自動的に pico が再起動します。再起動するとマスストレージとして認識されなくなりますので、パソコンから pico を取り外します。

#### 基板の配線

RepRap プロジェクトの RAMPS1.4 ボードの Thermistor の[回路図](https://reprap.org/wiki/File:RAMPS1.4schematic.png#metadata)を参考にして次のとおり配線しました。

{{< bsimage src="RAMPS1.4schematic.png" title="RAMPS1.4 ボードの回路図" >}}
{{< bsimage src="raspberry_pi_pico_schema.png" title="今回の回路図" >}}

現実の配線は次の写真の形になりました。

{{< bsimage src="raspberry_pi_pico_wiring.jpg" title="今回の回路図" >}}

#### printer.cfg の変更

Raspberry pi pico をセカンド MCU として使うための設定を `printer.cfg` に追加します。そのために pico に接続するためのシリアルポートを確認する必要がありますので、次の手順で確認します。

##### MCU の ID 調査

MCU の ID は KIAUH で簡単に確認できますので、`kiauh/kiauh.sh` を実行して 4) [Advanced] を選択します。

```
/=======================================================\
|     ~~~~~~~~~~~~~~~~~ [ KIAUH ] ~~~~~~~~~~~~~~~~~     |
|        Klipper Installation And Update Helper         |
|     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     |
\=======================================================/
/=======================================================\
|     ~~~~~~~~~~~~~~~ [ Main Menu ] ~~~~~~~~~~~~~~~     |
|-------------------------------------------------------|
|  0) [Log-Upload]   |       Klipper: Installed: 1      |
|                    |          Repo: Klipper3d/klipper |
|  1) [Install]      |                                  |
|  2) [Update]       |     Moonraker: Installed: 1      |
|  3) [Remove]       |                                  |
|  4) [Advanced]     |      Mainsail: Installed!        |
|                    |        Fluidd: Installed!        |
|                    | KlipperScreen: Not installed!    |
|  6) [Settings]     |  Telegram Bot: Not installed!    |
|                    |         Obico: Not installed!    |
|                    |                                  |
|  v5.0.0-14         |     Octoprint: Not installed!    |
|-------------------------------------------------------|
|                        Q) Quit                        |
\=======================================================/
####### Perform action: 4
```

それから 5) [Get MCU ID] を選択します。

```
/=======================================================\
|     ~~~~~~~~~~~~~~~~~ [ KIAUH ] ~~~~~~~~~~~~~~~~~     |
|        Klipper Installation And Update Helper         |
|     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     |
\=======================================================/
/=======================================================\
|     ~~~~~~~~~~~~~ [ Advanced Menu ] ~~~~~~~~~~~~~     |
|-------------------------------------------------------|
| Klipper & API:          | Mainsail:                   |
|  1) [Rollback]          |  6) [Theme installer]       |
|                         |                             |
| Firmware:               | System:                     |
|  2) [Build only]        |  7) [Change hostname]       |
|  3) [Flash only]        |                             |
|  4) [Build + Flash]     | Extras:                     |
|  5) [Get MCU ID]        |  8) [G-Code Shell Command]  |
|-------------------------------------------------------|
|                       B) « Back                       |
\=======================================================/
####### Perform action: 5
```

Raspberry pi と Raspberry pi Pico は USB 接続なので 1) USB を選択します。

```
/=======================================================\
|     ~~~~~~~~~~~~~~~~~ [ KIAUH ] ~~~~~~~~~~~~~~~~~     |
|        Klipper Installation And Update Helper         |
|     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     |
\=======================================================/
/=======================================================\
| Make sure that the controller board is connected now! |
|-------------------------------------------------------|
|                                                       |
| How is the controller board connected to the host?    |
| 1) USB                                                |
| 2) UART                                               |
|                                                       |
|-------------------------------------------------------|
|         B) « Back         |        H) Help [?]        |
\=======================================================/
###### Connection method: 1
```

そうすると 3Dプリンタのマザーボードと pico のシリアルポートが表示されます。`rp2040` が含まれる ID が Raspberry pi Pico なので、この ID をメモしておきます。ここでは `usb-Klipper_rp2040_E660C06213582227-if00` が pico の ID です。

```cfg
###### Identifying MCU connected via USB ...

 ● MCU #1: usb-Klipper_rp2040_E660C06213582227-if00
 ● MCU #2: usb-Klipper_stm32h743xx_2E0018000751303231393036-if00
```

##### printer.cfg 

これで `printer.cfg` を編集する準備が整いましたので、Raspberry pi pico をセカンド MCU とするために、2つ目の `[mcu]` セクションを追加して `serial:` に先程確認した ID を設定します。ID を設定するときは先頭に `/dev/serial/by-id/` を追加します。なお、`raspi_pico` の部分は任意の名称を設定できます。

```cfg
[mcu raspi_pico]
serial: /dev/serial/by-id/usb-Klipper_rp2040_E660C06213582227-if00
```

また、今回はサーミスタを交換していますので、新しいサーミスタのための設定が必要になります。

サーミスタの設定については、[公式ガイド](https://www.klipper3d.org/Config_Reference.html#thermistor)で `[thermistor]` セクションにサーミスタの温度毎の抵抗値を3組指定する方法と、温度と抵抗値の組み合わせを1つ指定するとともにβ値を指定する方法の2つが紹介されていますが、ここでは前者の方法を採用しました。なお、サーミスタの温度毎の抵抗値は、サーミスタメーカーの[データシート](https://atcsemitec.co.uk/product/semitec-nt-4-glass-thermistors/)で確認しました。

```cfg
[thermistor bed_thermistor]
temperature1: 25
resistance1: 100000
temperature2: 60
resistance2: 22480
temperature3: 100
resistance3: 5569
```

そして、`[heater_bed]` セクションの `sensor_type` に先程設定したサーミスタを指定しました。

```cfg
[heater_bed]
heater_pin: PG5
sensor_type: bed_thermistor
sensor_pin: raspi_pico:gpio27
```

これで、Raspberry pi pico を使ってベッドの温度を測定することができるようになりました。

{{% alert warning %}}
この状況で Raspberry pi pico を取り外したり基板からサーミスタが抜けたりすると、エラーが発生して印刷が強制終了しますので注意してください。
{{% /alert %}}


## XIAO RP2040 を使った Input Shaper の測定

XIAO RP2040 を使って Input Shaper を測定する方法を説明します。なお、Raspberry pi pico を使って測定する方法は、[(2) Raspberry Pi Pico as a secondary MCU for resonance testing working! : klippers](https://www.reddit.com/r/klippers/comments/owqvo2/raspberry_pi_pico_as_a_secondary_mcu_for/) や次の動画で解説されています。

<iframe width="560" height="315" src="https://www.youtube.com/embed/W_VHbT_tsZw" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

### BOM

1. Seeed Studio XIAO RP2040
1. ADXL345
1. Qiコネクタ

### 手順

#### Klipper のインストール

XIAO RP2040 に Klipper のファームウェアをインストールする方法は[上記の説明](#klipper-のインストール)とほぼ同じです。

違いは、XIAO RP2040 をブートローダーモードで起動するには、基板上の "B" ボタンを押しながら XIAO RP2040 をパソコンに接続し、パソコンに接続したら "B" を離すという手順が必要という点です。これで XIAO RP2040 がブートローダーモードで起動し、パソコンにマスストレージデバイスとして認識されますので、あとは Raspberry pi pico と同様に `klipper.uf2` を XIAO RP2040 にコピーします。

#### XIAO RP2040 への配線

これが一番苦労した点で、最初は同じことをしている人が公開している [XIAO RP2040 のケース](https://www.printables.com/model/166430-case-for-adafruit-qt-py-rp2040-to-control-adxl345)で紹介されていた配線方法を試しましたが、`ACCELEROMETER_QUERY` コマンドを実行しても `Invalid adxl345 id (got ff vs e5).` というエラーが返ってくるだけで上手くいきませんでした。また、そのページで紹介されている配線方法は XIAO RP2040 のデータシートに記載されているピン情報と合わなかったので、データシートに記載されたピン情報を基に配線を変えましたが、それでも同じエラーが返ってきました。そこでさらに調べると同じ配線で同じエラーに遭遇した人の相談が [Reddit](https://www.reddit.com/r/klippers/comments/x6uu33/assistance_requested_for_adxl_input_on_rp2040/) で見つかり、そのスレッドにある `printer.cfg` の設定を用いるとエラーを解消できました。

無事に動いた配線は次のとおりです。実際に配線する時は SilkScreen の表記を頼りに配線すれば OK だと思いますが、この後説明する `printer.cfg` では GPIO ピンの番号が必要なのでここに記載しています。なお、私が使っている ADXL345 は 3.3V で動作するタイプです。


| ADXL345 SilkScreen | XIAO RP2040 GPIO | XIAO RP2040 SilkScreen | RP2040 SPI |
|--------------------|------------------|------------------------|------------|
| SDO                | 4                | 9                      | MISO       |
| SDA                | 3                | 10                     | MOSI       |
| SCL                | 2                | 8                      | SCK        |
| CS                 | 1                | 7                      | CS         |
| VIN                |                  | 3V3                    |            |
| GND                |                  | GND                    |            |

XIAO RP2040 と ADXL345 の実際の配線状況は次のとおりです。XIAO RP2040 への配線がはんだ付けしたところからモゲる事態が何度も起きたため、2液性の接着剤で固めています。

{{< bsimage src="xiao_rp2040_wiring.jpg" title="XIAO RP2040 の配線の様子" >}}
{{< bsimage src="adxl345_wiring.jpg" title="ADXL345 の配線の様子" >}}

#### printer.cfg の変更

Raspberry pi pico を使うときと同様に、XIAO RP2040 をセカンド MCU として使うための設定を追加します。シリアルポートの確認方法は[上記の説明](#mcu-の-id-調査)と同じなので説明は省略します。

なお、Input Shaper を測定しない時は XIAO RP2040 を Raspberry pi から取り外すと思いますが、以下の設定を `printer.cfg` に直接書き込んで XIAO RP2040 を Raspberry pi から取り外すとエラーになります。それを避けるには、XIAO RP2040 を取り外す前に以下の設定をコメントアウトするか、または別の設定ファイル（例えば `adxl345.cfg` というファイル）に記述して `printer.cfg` に `[include adxl345.cfg]` を追加し、XIAO RP2040 を取り外す前にそのコードをコメントアウトする方法のいずれかを取る必要があります。後者の方が簡単なので、私は後者の方法を採用しています。

```cfg
# adxl345.cfg
[mcu xiao_rp2040]
serial: /dev/serial/by-id/usb-Klipper_rp2040_4150323833373205-if00
```

それから、ADXL345 を使うための設定を追加します。`[adxl345]` セクションの各項目に XIAO RP2040 の GPIO ピンの番号を指定しますが、プレフィックスとして `xiao_rp2040:` を追加する必要があります。

```cfg
[adxl345]
cs_pin: xiao_rp2040:gpio1
spi_software_sclk_pin: xiao_rp2040:gpio2
spi_software_mosi_pin: xiao_rp2040:gpio3
spi_software_miso_pin: xiao_rp2040:gpio4

[resonance_tester]
accel_chip: adxl345

probe_points: 115, 115, 20
```

また、`printer.cfg` に `adxl345.cfg` をインクルードするためのコードを追加します。

```cfg
# printer.cfg
# Input Shaper 測定時以外はコメントアウトしておく
#[include adxl345.cfg]
```

これで XIAO RP2040 を USB ケーブルで Raspberry pi に接続して `[include adxl345.cfg]` をアンコメントすれば XIAO RP2040 をセカンド MCU として使うことで Input Shaper を計測することができます。

なお、Input Shaper 計測に必要な numpy 等のライブラリのインストールは、[公式ガイド](https://www.klipper3d.org/Measuring_Resonances.html#software-installation)を参照してください。

#### 実際の計測

Input Shaper を計測するときは、まず XIAO RP2040 を Raspberry pi に接続し、それから `printer.cfg` の `#[include adxl345.cfg]` をアンコメントしてから Klipper を再起動します。

Klipper が再起動したら、`ACCELEROMETER_QUERY` コマンドを実行して ADXL345 の接続などを確認します。上手く接続できていれば `Recv: // adxl345 values (x, y, z): 470.719200, 941.438400, 9728.196800` という具合に現在の計測値が返ってきます。

あとは ADXL345 をプリンタに取り付けて `TEST_RESONANCES AXIS=X`、`TEST_RESONANCES AXIS=Y` コマンドを実行して XY 方向それぞれについて Input Shaper を計測します。なお、このコマンドは門型のプリンタ（Ender3 や Prusa MK3S+ 等）の場合のコマンドです。

計測が終わったら、`printer.cfg` の `[include adxl345.cfg]` をコメントアウトしてから Klipper を再起動し、XIAO RP2040 を取り外せば作業完了です。

この方法は XIAO RP2040 への配線という事前の一手間が必要ですが、一度配線してしまえば、計測の度に Raspberry pi のピンの位置を確認しながらジャンパケーブルで Raspberry pi と ADXL345 を接続する公式ガイドの方法より楽かなと思います。なので、しばらくはこの方法を続けてみようと思います。

## 参考情報

- [Measuring Resonances - Klipper documentation](https://www.klipper3d.org/Measuring_Resonances.html)
- [(2) Raspberry Pi Pico as a secondary MCU for resonance testing working! : klippers](https://www.reddit.com/r/klippers/comments/owqvo2/raspberry_pi_pico_as_a_secondary_mcu_for/)
- [Input Shaper with a Pi Pico - Klipper Tips - YouTube](https://www.youtube.com/watch?v=W_VHbT_tsZw&t=647s)
- [Overview - Seeed Wiki](https://wiki.seeedstudio.com/XIAO-RP2040/)
- [Case for Adafruit QT PY RP2040 and Seeed XIAO RP2040 (for ADXL345) by motocoder | Download free STL model | Printables.com](https://www.printables.com/model/166430-case-for-adafruit-qt-py-rp2040-to-control-adxl345)
- [(2) Assistance requested for ADXL input on RP2040 : klippers](https://www.reddit.com/r/klippers/comments/x6uu33/assistance_requested_for_adxl_input_on_rp2040/)
