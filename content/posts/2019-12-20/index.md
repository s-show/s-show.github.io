---
title: 'AnyCubic i3 Mega S に TMC2208 を導入する'
date: Fri, 20 Dec 2019 14:39:06 +0000
draft: false
tags: ['3Dプリンタ', '備忘録']
---

前置き
===

AnyCubic 製の AnyCubic Mega S という3Dプリンタを使っていますが、動作中にモーター音に加えて結構な大きさの電子音が鳴ってうるさいので、モータードライバを工場出荷時の A4988 から TMC2208 に交換しました。ただ、手順を紹介した記事が少なくて苦労しましたので、備忘録代わりに手順をまとめてみました。

なお、この記事の前提は次のとおりです。

プリンタの機種
: AnyCubic Mega S

マザーボード
: Trigorilla Mega2560+ramps 1.4

作業PC
: Windows10

必要なもの
=====

TMC2208
-------

Amazon や Aliexpress で「TMC2208」を検索するといくつかヒットしますが、バージョン違いがあるので注意が必要です。

私は FYSTEC社が販売しているVer.1.2を使いました。Ver.1.0と1.2の違いは、UART を使うときの設定方法のようです。

Marlin Firmware
---------------

TMK2208 のピン配置は、Mega Sに最初から取り付けられている A4988 と反対なので、TMC2208 を使う場合はマザーボードとモーターを繋ぐコネクタの向きを反対にする必要があります。

しかし、[Anycubic i3 Mega / Mega-S Marlin 1.1.9 Custom Firmware - Extra Features & Quality Tweaks](https://www.thingiverse.com/thing:3249319) を使うとコネクタの向きを変える必要が無いので、これを使うと便利です。というか、TMC2208のコネクタ以外にも便利な機能があるので、ぜひこのカスタムファームウェアをインストールするべきです。

Raspberry pi 3
--------------

Raspberry pi 3 に [OctoPrint](https://octoprint.org/) という3Dプリンタ制御用の OS を書き込んで、プリンタ制御や設定を行います。無くても交換できるが、交換後の設定変更などで非常に重宝しますし、今後の印刷や設定変更でも大活躍するので、この機会に導入しておいた方が良いと思います。

作業手順（TMC2208）
=============

TMC2208 は、工場出荷時点では StelthChop2 という静穏化を最重要視したモードになっています。このモードは、静穏化には有効な反面、トルクが弱い、チップが高温になるという問題があります。そこで、StelthChop2 より少しうるさいが、トルクが強く温度上昇も抑えられる SpreadCycle というモードを利用することにしました。

SpreadCycle モードを利用するには TMC2208 のマイコンの設定を変える必要があります。ブレッドボードに TMC2208 と抵抗等を差し込んで USB-シリアル変換装置で PC と繋げば書き込みできますが、専用の書き込み装置を使う方が簡単で FYSTEC 社は専用の書き込み装置も販売していますので、TMC2208 とあわせて購入すると便利です。

なお、TMC2208 のマザーボードとの接続パターンは次の3つがあるようです。

Legacy Mode
: ドライバを取り付けて電圧を調整すればOKという簡単な方法だが、StelthChop2 しか使えないようです。

Stand Alone Mode
: SpreadCycle モードが使えますが、TMC2208 を PC と接続して動作モードを変更する必要があります。私はこのパターンで接続しています。

UART Mode
: マザーボードとジャンパピンで接続してファームウェアのソースコードを修正したりと手間がかかりますが、その代わり、SPI でドライバをコントロールすることができるようです。

書き込み装置の準備
---------

書き込み装置を使うには次の作業が必要です。なお、書き込み作業は Windows10 で行なっています。

1.  書き込み装置にジャンパピンを2つ差し込む
2.  シリアル通信用のドライバをインストールする
3.  設定書き込みに使うソフトウェアをインストールする

まず、ジャンパピンは次の写真の2箇所に差し込みます。

{{< bsimage src="image1.png" title="TMC2208書き込み装置にジャンパピン取り付け" >}}

次に、シリアル通信用のドライバを [CH340 Drivers for Windows, Mac and Linux](https://sparks.gogo.co.nz/ch340.html) からダウンロードしてインストールします。

それから、TMC2208の設定を変えるために使う [ScriptCommunicator / serial terminal download | SourceForge.net](https://sourceforge.net/projects/scriptcommunicator/) をインストールし、専用のファイルである [Configurator for TMC220x | SilentStepStick | Watterott electronic](https://learn.watterott.com/silentstepstick/configurator/) をリンク先からダウンロードします。

TMC2208 の半田付け
-------------

上記の作業で PC と書き込み装置側の設定はOKですが、設定を変えるには、TMC2208 のパッドをハンダでブリッジする必要があります。ブリッジする箇所は次の写真のとおりです。

{{< bsimage src="image2.png" title="TMC2208の半田ブリッジ" >}}

SpreadCycleへの書き換え
-----------------

ここまでの作業が完了したら、書き込み装置をPCに接続し、デバイスマネージャーで書き込み装置の COMポート番号を確認します。それから、 `MC220X.scez` を ScriptCommunicator で開いて書き込み装置に TMC2208 を取り付けます。

TMC2208 を SpreadCycle モードで使う場合、OTPメモリの値を書き換える必要がありますので、`OPT Programmer` タブを開いて、次の手順で OTPメモリの値を書き換えます。

1.  OTP の値を `2.7` にするため、次の画面のとおり数値を入力して `write 1-bit to OTP memory` ボタンをクリック

{{< bsimage src="image3.png" title="TMC2208 のOTP書き換え1" >}}

2.  TOFF の値を `1.1` にするため、次の画面のとおり数値を入力して `write 1-bit to OTP memory` ボタンをクリック

{{< bsimage src="image4.png" title="TMC2208 のOTP書き換え2" >}}

作業手順（本体）
========

分解
--

### 底板の取り外し

椅子を隙間を空けて2つ並べ、その隙間にZ軸のフレームを通して本体を裏返すと作業が楽です。

{{< bsimage src="image5.png" title="AnyCubic Mega S の底板取り外し準備" >}}

なお、AnyCubic Mega S は、モータードライバを冷却するファンの吸気部分が塞がれていて吸気に問題がありますが、底板の手前と奥を180度回転させると吸気部分が開くので、この方法をお勧めします。

{{< bsimage src="image6.png" title="AnyCubic Mega S の底板の前後入れ替え" >}}


### モータードライバ用ファンの取り外し

作業の邪魔になるので、モータードライバ用のファンを取り外します。

モータードライバ交換
----------

X軸、Y軸、Z軸（左右で1つずつ）、エクストルーダーのモーターを制御するドライバ5個を全て取り外します。万が一、元のドライバに戻すことになった場合に備えて、ドライバの向きや、どのドライバがどこに差し込まれていたかを記録することをお勧めします。

モータードライバの電圧調整
-------------

テスターの端子を FYSTEC社の解説 Wiki で紹介している場所に当てます。YouTube の動画では同 Wiki とは異なる場所にテスターを当てていたりするが、どこで測定しても電圧は同じでした。

{{< bsimage src="image7.png" title="TMC2208 の電圧測定" >}}

プリンタの電源を入れてから、テスターを当てて電圧を測定します。電圧の設定ボルトについては、この後インストールするファームウェアの作者が提案している電圧に設定しました。（[リンク](https://www.thingiverse.com/thing:3249319/comments/#comment-2316929)）

X, Y, Z, E1 (E1 = 2nd Z axis)
: 1.1V

E0 (=extruder)
: 1.2V

Firmwareの書き込み
=============

Curaで書き込む方法
---------

Cura を立ち上げて「Settings > Printer > Manage Printers..」を開いたら、「Update Firmware > Upload Custom Firmware」をクリックしてカスタムファームウェアのファイルを選択します。

OctoPrintで書き込む方法
----------------

OctoPrint を起動して、ファームウェア作者の指示に沿って次のコマンドを実行します。なお、コマンドは Cura でも実行できますが、プリンタが返したメッセージが表示されないので、OctoPrint で作業をする方が楽です。

*   `M502` - load hard coded default values
*   `M92 E384` - set correct steps for the new extruder
*   `M203 E30` - limit extruder feedrate
*   `M204 R1500.00` - lower retract acceleration
*   `M500` - save the values

Accelaration & Jerk の設定
-----------------------

Accelaration & Jerk の設定を、ファームウェア作者の推奨値に変更します。

*   `M201 X2000 Y1500 Z60 E10000` ; max acceleration
*   `M204 P1200.00 R3000.00 T1500.00` ; default acceleration
*   `M205 S0.00 T0.00 Q20000 X9.00 Y9.00 Z0.40 E5.00` ; min segment time and jerk
*   `M500` - save the values

ヘッド移動のテスト
---------

OctoPrint のコントロール画面かプリンタのメニューでヘッドをホームポジションに移動させます。  
リミットスイッチがあるのでプリンタの制限以上に動かないはずですが、念のため、ヘッドの動きがおかしかったら直ちにプリンタの電源を切れるよう構えておきます。

MeshBedLeveling実行
-----------------

_5×5_ の25点のレベリングができるようになったので、印刷品質向上のためベッドのレべリングを調整します。[Anycubic i3 Mega / Mega-S Marlin 1.1.9 Custom Firmware - Extra Features & Quality Tweaks by davidramiro - Thingiverse](https://www.thingiverse.com/thing:3249319) の手順に従って行うこともできますし、OctoPrint にカスタムボタンを追加して行うこともできます。

テスト印刷 & キャリブレーション
=================

テスト印刷
-----

レベリングが適切にできているか確認するため、次のデータを印刷します。

*   [Bed test pattern for 200mm square bed. by N3wSp3ak - Thingiverse](https://www.thingiverse.com/thing:4011381)
*   [Customizable Bed Leveling Test by kenwebart - Thingiverse](https://www.thingiverse.com/thing:3507663)

レべリングの調整
--------

全体的にノズルが近い/遠い場合、OctoPrintのプラグインの [EEPROM Marlin Editor](https://plugins.octoprint.org/plugins/eeprom_marlin/) で Z軸のオフセットを調整してレベリングをカバーすることが可能です。

測定箇所毎のレべリングの値は `G29 S0` コマンドを実行すると以下のとおり確認できます。

```
Send: G29 S0
Recv: State: Off
Recv: Num X,Y: 5,5
Recv: Z offset: 0.00000
Recv: Measured points:
Recv:         0        1        2        3        4
Recv:  0 -0.35000 -0.18000 -0.01500 +0.18000 +0.42000
Recv:  1 +0.01000 +0.03000 +0.09000 +0.18000 +0.41000
Recv:  2 -0.01000 +0.09000 +0.11000 +0.13000 +0.45000
Recv:  3 +0.09000 +0.09000 +0.10000 +0.16000 +0.30000
Recv:  4 +0.06000 +0.11000 +0.17000 +0.17000 +0.29000
Recv: 
Recv: X:-5.00 Y:215.00 Z:23.41 E:372.56 Count X:-405 Y:17381 Z:9730
Recv: ok
```

レべリング確認の印刷で部分的にレベリングに問題があった場合、`G29 S3 Xn Yn Z-n.nn` コマンドで測定箇所毎にレべリングの値を変えられます。レべリングの値を変えた時は、`M500` コマンドで忘れずに保存すること。  
ちなみに、上記のコマンドで XY を指定する時は、以下のとおり指定します。

```
// XY軸の表示

         X1       X2       X3       X4       X5
Y1    -0.35000 -0.18000 -0.01500 +0.18000 +0.42000
Y2    +0.01000 +0.03000 +0.09000 +0.18000 +0.41000
Y3    -0.01000 +0.09000 +0.11000 +0.13000 +0.45000
Y4    +0.09000 +0.09000 +0.10000 +0.16000 +0.30000
Y5    +0.06000 +0.11000 +0.17000 +0.17000 +0.29000
```

このコマンドによる修正は、レベリングを完璧にするというよりも、どの部分でもノズルとベッドの距離が同じになることを目指します。どの部分でもノズルとベッドの距離が等しくなれば、あとは OctoPrint のプラグインの [EEPROM Marlin Editor](https://plugins.octoprint.org/plugins/eeprom_marlin/) で Z軸のオフセットを調整することでレベリングを完璧にすることができるようになります。

EEPROM Marlin Editor による Z軸のオフセットの調整は、`Steps -> Home Offset` で `Load` を押して現在の値を取得してから、`Z axis` のインプットボックスにオフセット値を書き込んで `Upload` をクリックしてオフセットを変更します。

正の値を入力するとベッドに近づき、値が増えるに従ってよりベッドに近づきます。逆に、負の値を入力するとベッドから遠ざかり、値が減少するに従ってよりベッドから遠ざかります。