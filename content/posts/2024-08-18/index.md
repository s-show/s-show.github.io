---
# type: docs 
title: Raspberry Pi と SKR Pico を UART で接続しながら KlipperScreen を使う方法 
date: 2024-08-15T20:55:49+09:00
featured: false
draft: false
comment: true
toc: true
tags: [3Dプリンタ,RaspberryPi]
---

## 前置き

現在オープンベータ中の [Fraxinus3e](https://fraxinus.jp) を組み立てて印刷を重ねていますが、操作のために毎回タブレットを使うのが若干面倒なので、KlipperScreen を導入することにしました。

note の [KlipperScreen を Raspberry Pi Zero 2W で使う方法](https://note.com/himura_mechatro/n/n77c8526a6e44) という記事を基にすればそんなに苦労しないかなと思って挑戦したのですが、実際には試行錯誤を重ねてやっと使えるようになりましたので、設定内容と試行錯誤の経緯を備忘録としてメモします。


## 環境

<dl>
  <dt>Raspberry Pi</dt>
  <dd>
    <dl>
      <dt>モデル</dt>
      <dd>Raspberry Pi 4 Model B Rev 1.2</dd>
      <dt>OS</dt>
      <dd>Debian GNU/Linux 11 (bullseye) 1.3.2</dd>
    </dl>
  </dd>
  <dt>Klipper</dt> 
  <dd>v0.12.0-192-gb7f7b8a3</dd>
  <dt>KlipperScreen</dt>
  <dd>v0.4.3-49-g8e915764</dd>
  <dt>Moonraker</dt>
  <dd>v0.8.0-359-g73df63db</dd>
  <dt>Raspberry Pi と SKR Pico の接続</dt>
  <dd>UART（Raspberry Pi の電源供給含む）</dd>
  <dt>ディスプレイ</dt>
  <dd>
    <a href="https://osoyoo.com/ja/2022/12/15/osoyoo-3-5-inch-spi-touch-display-for-rpi/">OSOYOO RPi用3.5インチSPIタッチディスプレイ</a>
  </dd>
</dl>

ディスプレイが前述の note の記事のものと違いますが、Discord の Fraxinus3e のサーバーでこのディスプレイを使って KlipperScreen を導入できたという投稿がありましたので、大丈夫だろうと思って購入しました。

## 設定内容の先取り

試行錯誤の過程はそこそこ長い話になっていますので、Raspberry Pi と SKR Pico を UART で接続しつつ、OSOYOO の 3.5inch ディスプレイに KlipperScreen の画面を表示させるために必要な作業をまず示します。

- UART2 を使用可能にする
- Raspberry Pi と SKR Pico の接続で使う TX のピンを GPIO14 から GPIO0 に、RX のピンを GPIO15 から GPIO1 にそれぞれ変更。
- `printer.cfg` の `[mcu]` の `serial:` を `ttyAMA0` から `ttyAMA1` に変更
- `raspi-config` で Linuxコンソール が UART にアクセスできるように設定
- Bluetooth を UART に接続させないために Bluetooth を無効化する（省略可）


## 試行錯誤

何とか成功させるまでに取り組んだことをこれから説明していきます。


### ディスプレイ導入

#### Raspberry Pi との接続

このディスプレイは、1枚目の写真のように Raspberry Pi にかぶせる形で取り付ける想定になっていますが、私の場合、もう1枚の写真のように Raspberry Pi の GPIO ピンの一部を SKR Pico との UART 接続で使っていますので、同じ接続方法は不可能でした。

{{< bsimage src="./img/attach_display.jpg" title="https://osoyoo.com/ja/2022/12/15/osoyoo-3-5-inch-spi-touch-display-for-rpi/ より" >}}
{{< bsimage src="./img/wiring_uart_1.png" title="https://github.com/bigtreetech/SKR-Pico/blob/master/Klipper/Images/wiring_uart.png より" >}}

そのため、ディスプレイの説明書で信号の送受信に使われているピンを確認し、それが Raspberry Pi のどのピンに対応しているか突合した上で、Qi コネクタを自作してディスプレイと Raspberry Pi を接続しました。なお、5V と GND については、SKR Pico の E0-STOP コネクタの 5V ピンと GND ピンを利用しています。

| ピン番号 | Rpi GPIO | GPIO機能 | ディスプレイ機能 | SKR Pico |
|----------|----------|----------|------------------|----------|
| 4(5V)    |          |          |                  | 5V       |
| 6(GND)   |          |          |                  | GND      |
| 11       | GPIO17   |          | TP_IRQ           |          |
| 18       | GPIO24   |          | LCD_RS           |          |
| 19       | GPIO10   | MOSI     | LCD_SI/TP_SI     |          |
| 21       | GPIO9    | MISO     | TP_SO            |          |
| 22       | GPIO25   |          | RST              |          |
| 23       | GPIO11   | SCLK     | LCD_SCK/TP_SCK   |          |
| 24       | GPIO8    | CE0      | LCD_CS           |          |
| 26       | GPIO7    | CE1      | TP_CS            |          |

{{< bsimage src="./img/rpi_gpio.JPEG" title="https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#gpio の画像を加工" >}}
{{< bsimage src="./img/display_gpio.JPEG" title="https://osoyoo.com/ja/2022/12/15/osoyoo-3-5-inch-spi-touch-display-for-rpi/ より" >}}
{{< bsimage src="./img/wiring_display.JPEG" title="Raspberry Pi とディスプレイを接続したときの配線" >}}


#### ドライバ導入

[メーカーの説明書](https://osoyoo.com/ja/2022/12/15/osoyoo-3-5-inch-spi-touch-display-for-rpi/)に従って以下の作業を実施しました。

- SSH で Raspberry Pi に接続
- `git clone https://github.com/osoyoo/LCD-show.git` コマンドで必要なファイルをクローン
- `cd LCD-show/` でクローンしたディレクトリに移動します。
- `chmod +x lcd35b-show` コマンドでドライバインストールのファイルに実行権限を付与
- `./lcd35b-show` コマンドを実行

これでドライバがインストールされ、設定も変更されて自動的に Raspberry Pi が再起動します。


### KlipperScreen 導入

公式サイトでは [KIAUH](https://github.com/dw-0/kiauh) を使ってインストールすることが推奨されていますので、それに従います。

`./kiauh/kiauh.sh` コマンドで KIAUH を起動したら、「1) [Install] -> 5) [KlipperScreen]」の順に選択して、KlipperScreen をインストールしました。


### Klipper に接続できなくなる

上記の作業だけでディスプレイに KlipperScreen の画面が表示されたのですが、ディスプレイに以下のエラーメッセージが表示されていました。

```
mcu 'mcu': Unable to connect
Once the underlying issue is corrected, use the
"FIRMWARE_RESTART" command to reset the firmware, reload the
config, and restart the host software.
Error configuring printer
```

{{< bsimage src="./img/error.JPEG" title="エラーメッセージが表示されている様子" >}}

仕方がないのでファームウェアを再起動したのですが、以下のメッセージがしばらく表示された後、同じエラーメッセージが表示されました。

```
Printer is not ready
The klippy host software is attempting to connect. Please
retry in a few moments.
```

これでは印刷できませんので同様の事例がないか検索したものの、私の事例に当てはまりそうなものはありませんでした。


#### ディスプレイの設定変更

検索で解決に繋がりそうな情報を見つけられなかったため、Discord の Fraxinus サーバーで状況を報告して相談を求めました。

すると [KlipperScreen を Raspberry Pi Zero 2W で使う方法](https://note.com/himura_mechatro/n/n77c8526a6e44) の執筆者の緋村さんから設定方法をアドバイスしていただきました。それを踏まえて、以下のとおり設定しました。


###### `config.txt` の編集

以下の設定を `[all]` セクションに追加して再起動しました。

```
dtoverlay=spi1-1cs,cs0_pin=16
dtoverlay=fbtft35,spi0-0,generic35,bgr,reset_pin=25,dc_pin=24,ledn_pin=18,rotate=270
dtoverlay=ads7846,cs=1,penirq=17,speed=10000,penirq_pull=2,xohms=155
```

###### Raspberry Pi 再起動後に以下のコマンドを実行

```bash
cd ~
mkdir dts
cd ~/dts
wget "https://drive.google.com/uc?export=download&id=1Eqbaq-SzO_6EFwNgEmxIW_iwfv7_77XB" -O fbtft35-overlay.dts
dtc -@ -I dts -O dtb -o fbtft35.dtbo fbtft35-overlay.dts
sudo cp fbtft35.dtbo  /boot/overlays/
sudo reboot
```

この設定を行ったところ、ディスプレイに KlipperScreen の画面は表示されましたが、上記と同じ `mcu 'mcu': Unable to connect ...` というエラーは続いていました。


#### Linux コンソールの設定変更

エラーの解消方法を探るために `klippy.log` を確認したところ、以下のログが複数出力されていましたので、エラーの原因はシリアル接続ではないかと当たりをつけました。

```
serialhdl.error: mcu 'mcu': Serial connection closed
mcu 'mcu': Timeout on connect
MCU error during connect
Traceback (most recent call last):
  File "/home/pi/klipper/klippy/mcu.py", line 791, in _mcu_identify
    self._serial.connect_uart(self._serialport, self._baud, rts)
  File "/home/pi/klipper/klippy/serialhdl.py", line 183, in connect_uart
    self._error("Unable to connect")
  File "/home/pi/klipper/klippy/serialhdl.py", line 61, in _error
    raise error(self.warn_prefix + (msg % params))
```

試しに、`printer.cfg` の `[mcu]` の `serial:` セクションに設定する接続先を `ttyAMA0` から `ttyS0` に変更してみました。すると、`mcu 'mcu': Unable to connect ...` エラーは引き続き発生していましたが、`klippy.log` に `permission denied` というエラーログが出ていました。`permission denied` は接続拒否なので、Klipper が接続しようとする前に別のプロセスがシリアル接続を押さえてしまっているのではないかと予想しました。

そこで Raspberry Pi のシリアル接続に関する情報を調べたところ、Raspberry Pi ではデフォルトで Linux コンソールがプライマリ UART に存在していることが分かりました[^1]。これがエラーの原因ではないかと考えて、Linux コンソールが UART にアクセスできないように設定を変更しました。設定変更は、`sudo raspi-config` を実行して「3 Interface Options -> I6 Serial Port」の順番でメニューを開き、「Would you like a login shell to be accessible over serial?」という質問に「No」を選択すれば OK です。

{{< bsimage src="./img/raspi-config1.png" title="" >}}
{{< bsimage src="./img/raspi-config2.png" title="" >}}
{{< bsimage src="./img/raspi-config3.png" title="" >}}

[^1]: https://www.raspberrypi.com/documentation/computers/configuration.html#primary-uart


#### Klipper の接続が復活

上記の設定変更後に Raspberry Pi を再起動したところ、Klipper の接続が復活して、Fluidd の画面が正常に戻りました。

しかし、ディスプレイには KlipperScreen の画面ではなく Linux 起動時のコンソールの内容が出力されていたため、次はこの問題の解消に取り組みました。


### ディスプレイに KlipperScreen の画面を表示させる

ディスプレイを初めて接続した時は KlipperScreen の画面が表示されており、そのときは Linux コンソールが UART に存在していたので、KlipperScreen の画面を表示させるには Linux コンソールが UART に存在している必要があると予想しました。しかし、Linux コンソールが UART に存在していると Klipper が接続できなくなってしまいます。

ただ、シリアル接続について調べていたときに、Raspberry Pi 4 では最大で UART を6つまで使えることが判明していました[^2]。そのため、Linux コンソールが UART に存在できるよう設定を戻した上で、使える UART を1つ増やしてそこに SKR Pico を接続すればよいのではと考えました。

[^2]: https://www.raspberrypi.com/documentation/computers/configuration.html#raspberry-pi-4-and-400


#### UART2 を使用可能にする

Raspberry Pi 4 では、デフォルトで UART0 と UART1 の2つの UART が使用可能になっており、このうち、UART1 がプライマリ UART になっています。一方、UART0 はセカンダリ UART になっていますが、通常は GPIO コネクタではなく Bluetooth コントローラーに接続されています。なお、UART1 と UART0 のどちらがプライマリになるかはモデルによって異なります。各モデルの設定は、Raspberry Pi の[公式ガイド](https://www.raspberrypi.com/documentation/computers/configuration.html#primary-and-secondary-uart)からコピーした下表のとおりです。

| Model                                       | Primary/console | Secondary/Bluetooth |
|---------------------------------------------|-----------------|---------------------|
| Raspberry Pi Zero                           | UART0           | UART1               |
| Raspberry Pi Zero W / Raspberry Pi Zero 2 W | UART1           | UART0               |
| Raspberry Pi 1                              | UART0           | UART1               |
| Raspberry Pi 2                              | UART0           | UART1               |
| Raspberry Pi 3                              | UART1           | UART0               |
| Compute Module 3 & 3+                       | UART0           | UART1               |
| Raspberry Pi 4                              | UART1           | UART0               |
| Raspberry Pi 5                              | UART10          | \<dedicated UART>   |

プライマリ UART とセカンダリ UART で UART1 と UART0 が使われていますので、`/boot/config.txt` に次の設定を追加して UART2 を使えるようにしました。[^3]

[^3]: なお、3Dプリンタ制御で Bluetooth は使わないはずなので、Bluetooth をオフにして UART0 に SKR Pico を繋げる方法もありそうですが、やり方が分からなかったのでこの方法は採用しませんでした。

```
enable_uart=1
dtoverlay=uart2
dtoverlay=disable-bt
```

設定の内容を説明しますと、`enable_uart=1` は UART を有効化するための設定で、`dtoverlay=uart2` は UART2 を使えるようにするための設定です。`dtoverlay=disable-bt` は Bluetooth デバイスを無効化するための設定で必須ではありませんが、Bluetooth を使う予定はないのでついでに設定しました。ファイルの編集が終わったら、Raspberry Pi を再起動します。

再起動後に `raspi-gpio get 0-15` コマンドで GPIO ピンに割り当てられた機能を確認しますと、GPIO0 と GPIO1 のピンの機能が TXD2 と RXD2 となっており、この2つのピンが UART2 のためのピンとなっていることが確認できます。

```
GPIO 0: level=1 fsel=3 alt=4 func=TXD2 pull=NONE
GPIO 1: level=1 fsel=3 alt=4 func=RXD2 pull=UP
GPIO 2: level=1 fsel=4 alt=0 func=SDA1 pull=UP
GPIO 3: level=1 fsel=4 alt=0 func=SCL1 pull=UP
GPIO 4: level=1 fsel=0 func=INPUT pull=UP
GPIO 5: level=1 fsel=0 func=INPUT pull=UP
GPIO 6: level=1 fsel=0 func=INPUT pull=UP
GPIO 7: level=1 fsel=1 func=OUTPUT pull=UP
GPIO 8: level=0 fsel=1 func=OUTPUT pull=UP
GPIO 9: level=0 fsel=4 alt=0 func=SPI0_MISO pull=DOWN
GPIO 10: level=0 fsel=4 alt=0 func=SPI0_MOSI pull=DOWN
GPIO 11: level=1 fsel=4 alt=0 func=SPI0_SCLK pull=DOWN
GPIO 12: level=0 fsel=0 func=INPUT pull=DOWN
GPIO 13: level=0 fsel=0 func=INPUT pull=DOWN
GPIO 14: level=1 fsel=2 alt=5 func=TXD1 pull=NONE
GPIO 15: level=1 fsel=2 alt=5 func=RXD1 pull=UP
```

また、`ls -la /dev/tty*` コマンドで UART のデバイスを確認したところ、以下のとおり `/dev/ttyAMA1` が追加されていました。

```
..
crw--w---- 1 root tty     204, 64 Aug 18 14:02 /dev/ttyAMA0
crw-rw---- 1 root dialout 204, 65 Aug 18 17:38 /dev/ttyAMA1
...
crw-rw---- 1 root dialout   4, 64 Aug 18 13:17 /dev/ttyS0
```


なお、`dtoverlay=disable-bt` で Bluetooth デバイスを無効化した場合、Raspberry Pi 再起動後に `sudo systemctl disable hciuart` を実行して Bluetooth のシステムサービスを停止する必要があるようです。[^4]

[^4]: https://www.raspberrypi.com/documentation/computers/configuration.html#uarts-and-device-tree 参照

#### Raspberry Pi と SKR Pico の接続を変更する

UART2 が使えるようになりましたので、プリンタの電源をオフにしてから Raspberry Pi と SKR Pico の接続を変更します。具体的には、GPIO14 に接続されているケーブルを GPIO0 に、GPIO15 に接続されているケーブルを GPIO1 に繋ぎ変えました。

{{< bsimage src="./img/UART2_TX_RX.JPEG" title="" >}}
{{< bsimage src="./img/wiring_uart_2.JPEG" title="" >}}


#### `printer.cfg` を修正する

`printer.cfg` の `[mcu]` の `serial:` を次のとおり変更しました。

```diff
- /dev/ttyAMA0
+ /dev/ttyAMA1
```


#### Linux コンソールを変更

`sudo raspi-config` を実行してLinux コンソールが UART にアクセスできるように設定を戻して、Raspberry Pi を再起動しました。


#### KlipperScreen の画面が表示される

以上の作業を経て、ディスプレイに KlipperScreen の画面を表示させつながら印刷もできるようになりました。

{{< bsimage src="./img/success.JPEG" title="" >}}


### 参考にした情報

この一連の作業で参考にしたサイトは次のとおりです。サイトの執筆者の方々には感謝申し上げます。

- [KlipperScreen を Raspberry Pi Zero 2W で使う方法](https://note.com/himura_mechatro/n/n77c8526a6e44)
- [Raspberry Piのシリアルポート設定（UART）を理解する - Toki Blog（トキブログ）](https://toki-blog.com/pi-serial/)
- [Raspberry Pi GPIOを使用したシリアル通信 | Ingenious](https://www.ingenious.jp/articles/howto/raspberry-pi-howto/gpio-uart/)
- [Configuration - Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/configuration.html)

