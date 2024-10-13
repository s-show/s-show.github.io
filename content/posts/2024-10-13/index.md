---
# type: docs 
title: QMK Firmware で DIP スイッチを使う方法
date: 2024-10-13T11:01:03+09:00
featured: false
draft: false
comment: true
toc: false
tags: [自作キーボード]
---

## 前置き

現在設計中のキーボードに DIP スイッチでデフォルトレイヤーを切り替える機能を登載するのですが、[公式リファレンス](https://docs.qmk.fm/features/dip_switch)の説明だけではつまずいてしまいそうなポイントもあったため、備忘録として使い方をまとめます。


## 環境

### QMK Firmware

```bash
❯ qmk --version
1.1.5
```

### マイコン

RP2040 を登載しているボードを使います。なお、テストに使ったマイコンボードは以下の3つです。

- [Raspberry Pi Pico](https://www.raspberrypi.com/products/raspberry-pi-pico/)
- [RP2040-Zero](https://www.waveshare.com/rp2040-zero.htm)
- [XIAO RP2040](https://www.seeedstudio.com/XIAO-RP2040-v1-0-p-5026.html)

## 実装

ここから実装方法を書いていきますが、昨今の QMK Firmware の [Data Driven Configuration | QMK Firmware](https://docs.qmk.fm/data_driven_config) の考え方に従って、可能な限り `(keyboard_name).json` に設定を記載する方法で進めていきます。なお、毎回 `(keyboard_name).json` とカッコ付きで書くのは面倒なので、以下では `keyboard.json` と書いていきます。


### `keyboard.json` 

DIP スイッチを使う場合、`keyboard.json` に次の設定を追加します。ちなみに、DIP スイッチをキーマトリックスの中に組み込む方法もあるようですが、今回は試していません。

```json
"dip_switch": {
    "enabled": true,
    "pins": [ "GP26", "GP27" ]
},
```

`"enabled: true" `が DIP スイッチの機能をオンにする設定で、`"pins: []"` が DIP スイッチを接続するピンを指定する設定です。ここではスイッチが2つある DIP スイッチを使うため、ピンを2つ指定しています。

なお、従来どおりの `rules.mk` と `config.h` で設定する場合、以下のとおり設定します。

```make
# rules.mk
DIP_SWITCH_ENABLE = yes
```

```c
// config.h
#define DIP_SWITCH_PINS { GP26, GP27 }
```

### ハードウェアの設定

DIPスイッチの片側を `keyboard.json` に設定したピンに接続し、もう片方を GND に接続します。

{{< bsimage src="image/wiring.png" title="DIP スイッチの配線" >}}

DIP スイッチ自体はただのスイッチなので、DIP スイッチのどちらのピンを `config.h` に設定したピンに接続してもOKです。

### QMK Firmware の設定

これで DIP スイッチを使う準備ができましたので、DIP スイッチを切り替えた時の動作を設定します。

DIP スイッチを切り替えた時の動作については、キーコードを送信するだけで足りる場合と、それだけでは足りない場合で設定が変わります。まず、キーコードを送信するだけで足りる場合の設定を解説します。


#### キーコードを送信するだけで足りる場合

キーボードの `keymaps/(keymap)/rules.mk` に以下の設定を追加します。

```make
DIP_SWITCH_MAP_ENABLE = yes
```

それから `keymap.c` に以下の設定を追加します。ここでは、以下の2つの設定を行っています。

- 1つ目の DIP スイッチをオンにした時に `DF(1)` を送信してレイヤー1をデフォルトレイヤーにし、オフにした時に `DF(0)` を送信してレイヤー0をデフォルトレイヤーにする。
- 2つ目の DIP スイッチをオンにした時に `AG_LSWP` を送信して `LALT` と `LWIN` を入れ替えて、オフにした時に `AG_LNRM` を送信して入れ替えを元に戻す。

```c
#if defined(DIP_SWITCH_MAP_ENABLE)
const uint16_t PROGMEM dip_switch_map[NUM_DIP_SWITCHES][NUM_DIP_STATES] = {
    DIP_SWITCH_OFF_ON(DF(0), DF(1)),
    DIP_SWITCH_OFF_ON(AG_LNRM, AG_LSWP),
};
#endif
```

#### 複数の処理を実行する場合

スイッチを切り替えたら複数の処理を実行する、スイッチを切り替えたら OLED の表示を変更する、といった対応するキーコードが無い処理については、スイッチ切り替えに合わせてコールバック処理を実行することで対応します。コールバック処理を行う場合、各スイッチの状態を個別に管理して条件分岐する方法と、スイッチの状態をまとめて管理して条件分岐する方法の2通りの方法がありますので、それぞれ説明します。

なお、いずれの場合であっても `keymaps/(keymap)/rules.mk` に `DIP_SWITCH_MAP_ENABLE = yes` を追加しているとコールバック処理が呼ばれませんので、この設定は削除してください。この点は本記事執筆時点の公式リファレンスでは明記されていませんので、注意してください。私はこの点になかなか気付かず苦労しました。

##### 各スイッチの状態を個別に管理する方法

`keymap.c` に `dip_switch_update_user(uint8_t index, bool active)` 関数を追加します。

引数の `index` はスイッチの順番で、`keyboard.json` の `dip_switch.pins` で指定した順番になります。`config.h` で指定している場合は `#define DIP_SWITCH_PINS {}` で指定した順番になります。`active` はスイッチがオンなら `true` になります。

上で紹介した処理をコールバック処理で実装した場合のコードは次のとおりとなります。なお、ここではデフォルトレイヤーを切り替える関数の [set_single_persistent_default_layer](https://docs.qmk.fm/ref_functions#setting-the-persistent-default-layer) と、LALT と LWIN を入れ替えるフラグの `keymap_config.swap_lalt_lgui` を利用しています。

```c
bool dip_switch_update_user(uint8_t index, bool active) {
    switch (index) {
        # 1つ目のDIPスイッチのオン・オフでデフォルトレイヤーを切り替え
        case 0:
            if (active) {
                set_single_persistent_default_layer(1);
            } else {
                set_single_persistent_default_layer(0);
            }
            break;
        # 2つ目のDIPスイッチのオン・オフで LALT と LWIN を入れ替え
        case 1:
            keymap_config.raw = eeconfig_read_keymap();
            if (active) {
                keymap_config.swap_lalt_lgui = true;
            } else {
                keymap_config.swap_lalt_lgui = false;
            }
    }
    return true;
}
```

##### スイッチの状態をまとめて取り扱う方法

`bool dip_switch_update_mask_user(uint32_t state)` を使うと、各スイッチの状態をビット列とみなした上で、そのビット列が表す値が引数の `state` に格納されます。例えば、スイッチの状態が次表の場合の `state` は `1` となります。

| スイッチ番号 | スイッチの状態 | ビット値 |
| ------ | ------- | ---- |
| スイッチ1  | ON      | 1    |
| スイッチ2  | OFF      | 0    |

また、スイッチの状態が次表の場合 `state` は `3` となります。

| スイッチ番号 | スイッチの状態 | ビット値 |
| ------ | ------- | ---- |
| スイッチ1  | ON      | 1    |
| スイッチ2  | ON      | 1    |

このように `state` の値で各スイッチの状態を管理できますので、あとは `switch` 文で条件分岐して処理を指定します。

```c
bool dip_switch_update_mask_user(uint32_t state) {
  switch (state) {
    case 0:
      // 
      break;
    case 1:
      // 
      break;
    case 2:
      // 
      break;
  // ...
  }
  return true;
}
```

なお、`state` の値を利用せずにスイッチの状態を直接ビット演算を使って管理する方法もあり、公式リファレンスで説明されています。

```c
bool dip_switch_update_mask_user(uint32_t state) { 
    if (state & (1UL<<0) && state & (1UL<<1)) {
        layer_on(_ADJUST); // C on esc
    } else {
        layer_off(_ADJUST);
    }
    if (state & (1UL<<0)) {
        layer_on(_TEST_A); // A on ESC
    } else {
        layer_off(_TEST_A);
    }
    if (state & (1UL<<1)) {
        layer_on(_TEST_B); // B on esc
    } else {
        layer_off(_TEST_B);
    }
    return true;
}
```

## 補足情報

### 分割型キーボードの右手側の DIP スイッチの管理

公式リファレンスでは分割型キーボードの右手側にある DIP スイッチを個別に管理する場合の設定も紹介されていますが、私が試したところ、右手側のスイッチを切り替えても `dip_switch_update_user()` と `dip_switch_update_mask_user()` 関数が実行されませんでした。

試行錯誤の過程でマイコンボードを ProMicro に変更したり、左右判定の設定を変更したりしましたが、原因は突き止められませんでした。ただ、DIP スイッチは片方にあれば足りるので、左右に DIP スイッチを配置するのはあきらめました。


### デフォルトレイヤーを切り替える方法

デフォルトレイヤーの切り替えは `DF(layer)` キーを送信すれば可能ですが、このキーは `tap_code()` では送信できません。

そのため、上記の `dip_switch_update_user()` を使う処理でのデフォルトレイヤーの切り替えは `set_single_persistent_default_layer()` 関数で処理しています。

### LALT と LWIN キーを入れ替える方法

LALT と LWIN キーは `QK_MAGIC_SWAP_LALT_LGUI` や `AG_LSWP` キーで入れ替えできます。また、`QK_MAGIC_UNSWAP_LALT_LGUI` や `AG_LNRM` キーで元に戻せますが、このキーも `tap_code()` では送信できません。

そこでキーの送信以外で入れ替えを実現できないか調べたところ、`QK_MAGIC_SWAP_LALT_LGUI` は `keymap_config.swap_lalt_lgui` 変数を `true/false` にすることでキーの入れ替えを実現していることが判明しましたので、上記のコードでは `keymap_config.swap_lalt_lgui` 変数を `true` または `false` にして LALT と LWIN キーの入れ替えを実現しています。

なお、`QK_MAGIC_SWAP_LALT_LGUI` は `quantum/process_keycode/process_magic.c` で以下のとおり定義されています。

```c
// quantum/process_keycode/process_magic.c
// 関係するコードのみ抜粋しています

/**
 * MAGIC actions (BOOTMAGIC without the boot)
 */
bool process_magic(uint16_t keycode, keyrecord_t *record) {
    // skip anything that isn't a keyup
    if (record->event.pressed) {
        if (IS_MAGIC_KEYCODE(keycode)) {
            /* keymap config */
            keymap_config.raw = eeconfig_read_keymap();
            switch (keycode) {
                case QK_MAGIC_SWAP_LALT_LGUI:
                    keymap_config.swap_lalt_lgui = true;
                    break;
                case QK_MAGIC_UNSWAP_LALT_LGUI:
                    keymap_config.swap_lalt_lgui = false;
                    break;
```

### デフォルトレイヤーの確認方法

例えば、DIP スイッチのオン・オフでデフォルトレイヤーを切り替える（QWERTY 配列レイヤー ⇔ COLEMAK 配列レイヤー）場合、QMK の機能でデフォルトレイヤーのレイヤー番号が取得できると LED インジケータの変更などに利用できそうです。

しかし、`MO(layer)` などによる一時的なレイヤーの切り替えでは `get_highest_layer(layer_state)` 関数で使用中のレイヤー番号を取得できますが、デフォルトレイヤーのレイヤー番号は常に `0` になるため、どのレイヤーをデフォルトレイヤーにしているか調べる方法は無い模様です。

そのため、デフォルトレイヤーの切り替えで LED インジケータなどを変更する場合、デフォルトレイヤーの切り替え時に「どのレイヤーをデフォルトレイヤーに設定したか」という情報を保存し、インジケータの更新処理などでその変数を参照して対処するしかなさそうです。

なお、デフォルトレイヤーのレイヤー番号が常に `0` になるという点については、QMK のコントリビュータの Drashna 氏が以下の Issues で発言しています。私の方でも QMK のデバッグ機能でデフォルトレイヤー切り替え時に `get_highest_layer(layer_state)` 関数が返す値を確認したところ、常に `0` になるのを確認しています。

[# [Bug] default_layer_state is 0 when the keyboard is powered up after flashing.](https://github.com/qmk/qmk_firmware/issues/13196#issuecomment-860146005)
