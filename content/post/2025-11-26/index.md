---
# type: docs
title: QMK Firmware の LED インジケータと RGB LED のメモ
date: 2025-11-25T00:03:22+09:00
featured: false
draft: false
comment: true
toc: true
tags: [自作キーボード]
archives: 2025/11
---

## 前置き

新しいキーボードの設計に着手しているのですが、今度のキーボードはテンキーを統合したいと思っているので、テンキーのオン・オフを確認するためのインジケータも必要になります。また、レイヤー切り替えを視覚的に分かりやすくするため、レイヤー毎に違う色で点灯する LED も追加したいと考えています。

しかし、QMK Firmware にインジケータ機能や RGB LED を使うための機能があることは知っていましたが、実際に使ったことがありませんでした。そこで、実験基板を作って部品の選定や QMK Firmware の設定方法を確認することにしました。

そして、実験基板でインジケータ機能と RGB LED を使うことができましたので、備忘録として情報を整理します。

## LED インジケータ

### LED インジケータとは？

Numlock，Caps lock，Scroll lock のオン・オフに合わせて LED インジケータを点灯・消灯させる機能です。

### 必要なパーツ

インジケータとして LED が必要です。この機能はインジケータを点灯・消灯させるだけで色の指定はできないため、LED は単色のもので問題ありません。

私は JLCPCB の在庫から適当にサイズ 1608 で 100mW の白色 LED に 4.7kΩの抵抗を組み合わせて使いましたが、ちょうど良い光量になりました。

#### 抵抗値の求め方

抵抗の抵抗値については、最初は秋月電子通商が公表している「[LED・抵抗の計算式](https://akizukidenshi.com/goodsaffix/led-r-calc.pdf)」の

> （電源電圧［Ｖ］－順方向電圧降下［Ｖ］）÷順方向電流［Ａ］＝抵抗値［Ω］

に以下の値を代入して求めてみた。

- 電源電圧: 3.3V
- 順方向電圧降下(VF): 3.1V
- 順方向電流: 5mA

しかし、これだと抵抗値が 40Ωとなり、ネットで一般的に見つかる 4.7kΩなどの値とかけ離れた値になってしまいました。そこで Discord の Self-Made Keyboard in Japan で相談したところ、電流を 5mA 流すと非常に眩しくなってしまうので、5.1kΩぐらいの抵抗で十分視認できるというアドバイスをいただきました。

そのため、とりあえず 4.7kΩの抵抗を選択しましたが、結果的に問題ない光量になりましたので、本番でも同じ抵抗を使おうと思います。

### QMK の設定

`keyboard.json` に以下の設定を追加します。`"GPxx"` は Raspberry pi Pico のピン番号です。

```json
"indicators": {
    "num_lock": "GP28",
    "caps_lock": "GP27",
    "scroll_lock": "GP26"
    "on_state": 0
},
```

`"on_state"` を `0` にしているのは、LED の回路を負論理にしているためです。

## RGB LED

### RGB LED とは？

アドレサブル RGB 対応の LED を指定した色・明るさ・アニメーションで点灯させる機能。タイピングに合わせて点灯させたり、レイヤー切り替えに合わせて違う色で点灯させたりできる。

### 必要なパーツ

アドレサブル RGB 対応の LED が必要です。QMK Firmware が対応している LED は以下のとおりです。

- WS2811, WS2812, WS2812B, WS2812C, etc.
- SK6812, SK6812MINI, SK6805
- APA102

私は、WS2812 のクローン品と呼ばれており、かつ、遊舎工房で取り扱っている [SK6812MINI-E（10個入り）](https://shop.yushakobo.jp/products/sk6812mini-e-10?variant=40047782953121) を使うことにしました。

LED の電源については、Raspberry pi pico の VBUS を使って確保することにしました。Raspberry pi pico の VBUS は、Raspberry pi pico を USB で接続していれば、USB の 5V 電源が直接流れるため、これで電源は確保できます。

なお、[SK6812MINI-E](https://akizukidenshi.com/goodsaffix/sk6812-mini_rev08_e.pdf) のデータシートでは、データライン (DIN) のロジック HIGH のしきい値 (VIH) は 0.7 * VDD 以上となっています。そのため、電源に 5V を使うとしきい値は 0.7 * 5V = 3.5V となります。しかし、Raspberry pi pico の GPIO が供給できる電圧は 3.3V なので、理論上は 3.3V の電圧を 3.5V 以上に昇圧しなければ SK6812MINI-E を制御できないことになります。

しかし、[【ソースコード有り】QMKキーボードに Caps Lockや Scroll Lock等の LEDインジケータ機能を追加する方法 (How to add Caps Lock Scroll Lock LED indicators to QMK Keyboard)](http://www.neko.ne.jp/~freewing/hardware/qmk_keyboard_led_indicator/) で紹介されているキーボードは 3.3V の電圧で SK6812MINI-E を制御しているそうなので、まずは実験として 3.3V のまま制御できるか試すことにしました。

実験の結果、SK6812MINI-E 1つであれば問題なく制御できました。

### QMK の設定

`keyboard.json` に以下の設定を追加します。`"rgblight.default"` は設定しなくても動作しますが、デフォルトの点灯色を白色にしたかったので、以下のとおり設定しています。

```json
"rgblight": {
    "led_count": 1,
    "default": {
        "hue": 0,
        "sat": 0,
        "val": 64
    },
    "driver": "ws2812",
    "layers": {
        "enabled": true,
        "max": 16
    },
    "sleep": true
    "max_brightness": 64
},
"ws2812": {
    "driver": "vendor",
    "pin": "GP20"
},
```

`"GP20"` は、Raspberry pi Pico のピン番号です。

それから、`rules.mk` に以下の設定を追加します。

```
RGBLIGHT_ENABLE = yes
```

そして、`keymap.c` にレイヤー切り替え時に SK6812MINI-E の点灯色を変える処理を追加します。

```c
layer_state_t layer_state_set_user(layer_state_t state) {
    switch (get_highest_layer(state)) {
    case 1:
        rgblight_sethsv (128, 255, 64);
        break;
    case 2:
        rgblight_sethsv (28, 255, 64);
        break;
    case 3:
        rgblight_sethsv (85, 255, 64);
        break;
    case 4:
        rgblight_sethsv (213, 255, 64);
        break;
    default: //  for any other layers, or the default layer
        rgblight_sethsv (0, 0, 64);
        break;
    }
  return state;
}
```

なお、`rgblight_sethsv()` ではなく `rgblight_setrgb()` でも色は変えられますが、`rgblight_setrgb()` で色を変えると何故か明るさも変わってしまう（デフォルト値より明らかに明るくなってしまう）ため、`rgblight_sethsv()` を使っています。 

#### 補足

最初にファームウェアをビルドしたときはデフォルトの点灯色を設定していなかったため、SK6812MINI-E は QMK Firmware のデフォルトの赤色に点灯しました。しかし、デフォルトの点灯色を白色にしたかったので、`keyboard.json` の `"rgblight.default"` セクションに上記の設定を追加してビルドして Raspberry pi pico に書き込みました。

しかし、SK6812MINI-E の点灯色が変わりませんでした。そこで同じ設定を `config.h` に移動させてみましたが、それでも結果は変わりませんでした。

そこでやむを得ず Google Gemini に相談したところ、EEPROM に古い設定が残っている可能性が高いと回答されましたので、合わせて回答された EEPROM のリセット方法を実行してから再度ファームウェアを書き込んだところ、無事に設定したとおり白色で点灯してくれました。

**EEPROM のリセット方法**

**Bootmagic Lite を使う** (`keyboard.json` で `"bootmagic": true` と設定していることが前提)
1. USBケーブルを抜く
1. マトリックスの **(0,0) のキー**（`LAYOUT` の一番左上のキー）を押したままにする
1. キーを押したまま USB ケーブルを挿す
1. 数秒待ってからキーを離す

## まとめ

実験基板を使って LED インジケータと RGB LED の設定を確認できましたので、本番のキーボード設計に反映していこうと思います。

本記事がどなたかの参考になれば幸いです。

## 参考にしたサイト

- [LED Indicators | QMK Firmware](https://docs.qmk.fm/features/led_indicators)
- [【ソースコード有り】QMKキーボードに Caps Lockや Scroll Lock等の LEDインジケータ機能を追加する方法 (How to add Caps Lock Scroll Lock LED indicators to QMK Keyboard)](http://www.neko.ne.jp/~freewing/hardware/qmk_keyboard_led_indicator/)
- [RGB Lighting | QMK Firmware](https://docs.qmk.fm/features/rgblight)
- [【自作キーボード / 電子工作】RP2040など3.3VマイコンでNeoPixel RGB LED(WS2812B / SK6812)を点灯させるには！ | ぶらり＠web走り書き](https://burariweb.info/electronic-work/neopixel-drive-voltage-logic-level.html)
