---
# type: docs 
title: RP2040 で QMK Firmware を使うメモ
date: 2023-03-06T22:39:17+09:00
featured: false
draft: false
comment: true
toc: false
categories: []
tags: [自作キーボード]
---

## 前置き

[天下一キーボードわいわい会 Vol.4 - connpass](https://tenkey.connpass.com/event/273910/) にキーボードを出展するためにケースを新規作成しましたが、それに合わせて、以前から実現したかった USB Type-C 化を実現するため、以前購入して上手く使えなかった [sekigon-gonnoc/pico-micro: A Pro Micro compatible board with RP2040 and mid-mount USB-C receptacle](https://github.com/sekigon-gonnoc/pico-micro) を使いました。RP2040 で QMK Firmware を動かすのは初めてで、使えるようになるまで多少の試行錯誤がありましたので、備忘録として必要な作業をまとめました。

なお、RP2040 を使う前は Pro Micro を使っており、その時の設定ファイルは [qmk_firmware/keyboards/yamanami at yamanami_keyboard · s-show/qmk_firmware · GitHub](https://github.com/s-show/qmk_firmware/tree/yamanami_keyboard/keyboards/yamanami) のとおりで、RP2040 を使う場合の設定ファイルは [qmk_firmware/keyboards/yamanami_rp2040 at yamanami_keyboard · s-show/qmk_firmware · GitHub](https://github.com/s-show/qmk_firmware/tree/yamanami_keyboard/keyboards/yamanami_rp2040) のとおりです。

## ボードと MCU の変更

まず、マイコンボードを Pro Micro から PICO Micro に切り替えるため、MCU とブートローダーの設定を次のとおり変更しました。

```diff
- MCU = atmega32u4
+ MCU = RP2040
- BOOTLOADER = caterina
+ BOOTLOADER = rp2040
```

## ピン指定の変更

PICO Micro は Pro Micro との間でフットプリントとピン配置に互換性がありますが、RP2040 を使う時はピンの指定を GPIO の番号で指定する必要があるため、以下の対応表を作成してピンの指定を修正しました。

<table>
<caption>Pro Micro と PICO Micro のピンの対応表</caption>
<thead>
  <tr>
    <th class="thead" scope="col">Pro Micro</th>
    <th class="thead" scope="col">PICO Micro</th>
    <th class="thead" scope="col">Pro Micro</th>
    <th class="thead" scope="col">PICO Micro</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>D3</td> <td>GP0</td> <td>B5</td> <td>GP9</td>
  </tr>
  <tr>
    <td>D2</td> <td>GP1</td> <td>F4</td> <td>GP29</td>
  </tr>
  <tr>
    <td>D1</td> <td>GP2</td> <td>F5</td> <td>GP28</td>
  </tr>
  <tr>
    <td>D0</td> <td>GP3</td> <td>F6</td> <td>GP27</td>
  </tr>
  <tr>
    <td>D4</td> <td>GP4</td> <td>F7</td> <td>GP26</td>
  </tr>
  <tr>
    <td>C6</td> <td>GP5</td> <td>B1</td> <td>GP22</td>
  </tr>
  <tr>
    <td>D7</td> <td>GP6</td> <td>B3</td> <td>GP20</td>
  </tr>
  <tr>
    <td>E6</td> <td>GP7</td> <td>B2</td> <td>GP23</td>
  </tr>
  <tr>
    <td>B4</td> <td>GP8</td> <td>B6</td> <td>GP21</td>
  </tr>
</tbody>
</table>


```diff
- #define MATRIX_ROW_PINS { F4, C6, D7, E6 }
+ #define MATRIX_ROW_PINS { GP29, GP5, GP6, GP7 }
- #define MATRIX_COL_PINS { F5, F6, F7, B1, B3, B6 }
+ #define MATRIX_COL_PINS { GP28, GP27, GP26, GP22, GP20, GP21 }
- #define MATRIX_ROW_PINS_RIGHT { F7, B1, B3, B2 }
+ #define MATRIX_ROW_PINS_RIGHT { GP26, GP22, GP20, GP23 }
- #define MATRIX_COL_PINS_RIGHT { D4, C6, D7, E6, B4, B5 }
+ #define MATRIX_COL_PINS_RIGHT { GP4, GP5, GP6, GP7, GP8, GP9 }
```

{{< bsimage src="PICO_Micro_PIN.png" title="PICO Micro のピン配置" >}}

## 左右間のシリアル通信の設定

Pro Micro を使うときは `rules.mk` に `SPLIT_KEYBOARD = yes` を指定して `config.h` に `#define USE_SERIAL` と `#define SOFT_SERIAL_PIN D2` を追加すれば左右間のシリアル通信を設定できましたが、RP2040 では `SOFT_SERRIAL_PIN` が定義されていないため、次の順番で設定を修正しました。

まず、公式リファレンスで「RP2040 を使う時は `SOFT_SERIAL_PIN` の代わりに `SERIAL_USART_TX_PIN` を使うこと」と指定されており、私の設計では Pro Micro の `D2` ピンでシリアル通信していましたので、`config.h` の `SOFT_SERIAL_PIN D2` を `#define SERIAL_USART_TX_PIN GP1` に修正しました。

```diff
- #define SOFT_SERIAL_PIN D2
+ #define SERIAL_USART_TX_PIN GP1
```

{{< bsimage src="My_Keyboard_Scheme.png" title="私のキーボードの回路図" >}}

それから、私のキーボードではシリアル通信に使える線が一本だけで全二重通信によるシリアル通信はできないため、半二重通信でシリアル通信するために `#define USE_SERIAL` を `#define SERIAL_USART_HALF_DUPLEX` に変更しました。

```diff
- #define USE_SERIAL
+ #define SERIAL_USART_HALF_DUPLEX
```

そして、`rules.mk` に `SERIAL_DRIVER = vendor` を追加すれば左右間のシリアル通信の設定は完了です。

```diff
SPLIT_KEYBOARD = yes
+ SERIAL_DRIVER = vendor
```

## その他の設定

Pro Micro を使っているときはキーボードのリセットボタンを押せば Pro Micro がブートローダーモードになってファームウェアを更新できましたので、同じ機能を追加するため `config.h` に次の設定を追加しました。

```diff
+ #define RP2040_BOOTLOADER_DOUBLE_TAP_RESET
+ #define RP2040_BOOTLOADER_DOUBLE_TAP_RESET_TIMEOUT 500U
```

これでキーボードのリセットボタンを2連打すれば PICO Micro がブートローダーモードになって `uf2` ファイルを書き込めるようになりますので、ファームウェア更新の手間を減らすため設定を追加した。

## 参考にしたウェブページ

[‘serial’ Driver](https://docs.qmk.fm/#/serial_driver)

[Raspberry Pi RP2040](https://docs.qmk.fm/#/platformdev_rp2040)

[sekigon-gonnoc/pico-micro: A Pro Micro compatible board with RP2040 and mid-mount USB-C receptacle](https://github.com/sekigon-gonnoc/pico-micro)

[Lunakey PicoでQMK Firmwareを動かしてみました](https://www.eisbahn.jp/yoichiro/2022/08/luankey_pico_qmk_firmware.html)
