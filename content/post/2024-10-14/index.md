---
# type: docs 
title: QMK Firmware でカラー LCD に画像を表示する方法
date: 2024-10-13T15:37:03+09:00
featured: false
draft: false
comment: true
toc: false
tags: [自作キーボード]
archives: 2024/10
---

## 前置き

構想中の左手用キーボードでカラー LCD を使うためのテストとして Raspberry pi pico でカラー LCD を使ってみたのですが、使うためには公式リファレンスの [Quantum Painter](https://docs.qmk.fm/quantum_painter) に加えて [SPI Master Driver](https://docs.qmk.fm/drivers/spi) も確認する必要があり、色々苦労しましたので、使い方を忘れないうちに備忘録としてまとめます。

## 環境

### QMK Firmware

```bash
❯ qmk --version
1.1.5
```

### マイコン

Raspberry Pi Pico を使います。

### カラーLCD

[Tztft-arduino用LCDディスプレイモジュール,ラウンド,rgb,240x240,gc9a01ドライバー,4ワイヤー,spiインターフェイス,240x240, PCB, 1.28インチ - AliExpress 502](https://ja.aliexpress.com/item/1005006310858096.html?spm=a2g0o.order_list.order_list_main.5.15ed585afMurQS&gatewayAdapt=glo2jpn) を使っています。LCDドライバーが GC9A01 であれば同じ方法で使えると思います。

なお、現在の QMK Firmware が対応している LCD ドライバは、公式リファレンスの "Supported devices" で確認できます。私は丸型のディスプレイを使ってみたかったので、上記の商品を選択しました。

## 事前準備

ここから LCD に画像を表示するための事前準備について説明します。なお、本記事の執筆時点ではカラー LCD の設定は `(keyboard_name).json` に書けないため、`config.h` や `rules.mk` に設定します。

また、カラー LCD にはテキストや図形も描画できますが、私が描画したいのは画像なので、画像を描画するための設定を説明します。


### `rules.mk` 

`rules.mk` にカラー LCD のドライバに合わせた設定を書きます。今回使うドライバは GC9A01 なので、公式リファレンスに従って以下の設定を追加します。

```make
# rules.mk
QUANTUM_PAINTER_ENABLE = yes
QUANTUM_PAINTER_DRIVERS += gc9a01_spi
```

`rules.mk` には LCD に表示する画像ファイルの設定も書きますが、その点は後ほど説明します。

### `config.h` 

`config.h` に公式リファレンスの [Quantum Painter](https://docs.qmk.fm/quantum_painter) と [SPI Master Driver](https://docs.qmk.fm/drivers/spi#chibiosarm-configuration) に従って LCD と SPI の設定を追加します。

#### LCD の設定

LCD の設定は以下のとおりです。大まかな説明はコメントに書いていますので、細かい説明はコードの後に書きます。

```c
/* config.h */

// マイコンと LCD の通信に使うピンを定義
// Raspberry pi pico の SPI0 のピンの近くのピンを適当に選択
#define LCD_RST_PIN GP4
#define LCD_DC_PIN GP6
#define LCD_CS_PIN GP5
#define LCD_BLK_PIN GP10

// マイコンの動作クロックを割り算するための値
#define LCD_SPI_DIVISOR 2

// 画像を回転させないので回転角度を 0°に設定
#define LCD_ROTATION QP_ROTATION_0

// 今回の LCD の解像度（240x240）を設定
#define LCD_HEIGHT 240
#define LCD_WIDTH 240

// ドライバとディスプレイで原点にズレがないためオフセットは0に設定
#define LCD_OFFSET_X 0
#define LCD_OFFSET_Y 0

// 今回の LCD では色を反転させる必要がないのでコメントアウト
//#define LCD_INVERT_COLOR

// 256色の画像を扱うための設定
#define QUANTUM_PAINTER_SUPPORTS_256_PALETTE TRUE

// LCD に表示させる画像の数を設定
#define QUANTUM_PAINTER_NUM_IMAGES 9

// 画面を常時点灯にするためタイムアウト時間を 0 に設定
#define QUANTUM_PAINTER_DISPLAY_TIMEOUT 0
```

##### #define LCD_SPI_DIVISOR 4

マイコンの動作クロックを割り算して SPI デバイスの動作クロックに合わせるための設定のようです。Raspberry pi pico の RP2040 の動作クロックが 125MHz というのは分かるのですが、GC9A01 の動作クロックが分からなかったので、とりあえずデフォルト値の `2` にしています。 

##### #define LCD_ROTATION

画像を回転させる角度を指定します。回転は90°単位で、`QP_ROTATION_0`、`QP_ROTATION_90`、`QP_ROTATION_180`、`QP_ROTATION_270` の中から選択します。

##### #define QUANTUM_PAINTER_SUPPORTS_256_PALETTE

256色のカラー画像またはモノクロ画像を扱う時に必要な設定です。もし、65536色の画像を扱う時は `QUANTUM_PAINTER_SUPPORTS_NATIVE_COLORS` を `TRUE` に、16777216色の画像を扱う時は `QUANTUM_PAINTER_SUPPORTS_NATIVE_COLORS` を `TRUE` に設定します。

##### #define QUANTUM_PAINTER_NUM_IMAGES

LCD に表示させる画像の数を設定するものですが、デフォルト値が `8` なので大抵の場合は設定不要ではないかと思います。今回はテストなのでデフォルト値を越えた数の画像を扱う設定にしています。

##### #define QUANTUM_PAINTER_DISPLAY_TIMEOUT

デフォルト値の `30000` だと画面が30秒で暗転するので、`0` を設定して常時点灯にしています。

#### SPI の設定

SPI は以下のとおり設定しています。大まかな説明はコメントに書いていますので、細かい説明はコードの後に書きます。

```c
/* config.h */

// マイコンと LCD の通信に使うピンを定義
// Raspberry pi pico の SPI0 のピンから適当に選択
#define SPI_SCK_PIN GP2
#define SPI_MOSI_PIN GP3

// LCD にMISO ピンに当たる端子が無いので `NO_PIN` を設定
#define SPI_MISO_PIN NO_PIN

#define SPI_DRIVER SPID0
#define SPI_MODE 0
```

##### #define SPI_MOSI_PIN

この設定には苦労しました。というのも、商品ページでは SPI 通信対応と書いてあるのに、実際の商品に書かれているピンの名称は I2C 通信で使う "SDA" や "SCL" なので、どう対応するかが分かりませんでした。参考にしたサイトで「SCL ⇔ SCK」、「SDA ⇔ TX ⇔ MOSI」という対応が書かれているのを見つけられたので何とか設定できました。

##### #define SPI_DRIVER

`SPI_DRIVER` はデフォルトで "SPI2" を使う設定になっていますが、Raspberry pi pico に "SPI2" はありませんので、"SPI0" を使う設定にしています。

##### #define SPI_MODE

`SPI_MODE` には `0 - 3` の値が設定可能で、手元の LCD が動いたのは `0, 1, 3` なので、参考にしたサイトと同じ `0` を選択しています。ドライバによっては `3` でないと動かないものもあるみたいです。

ここまでの設定のうち、Raspberry pi pico と LCD の通信にかかるピンの設定を抜粋すると次表のとおりとなります。Raspberry pi pico と LCD を結線するときの参考になります。

| config.h   | Raspberry pi pico GPIO Pin | LCD Pin |
|--------------|----------------------------|---------|
| LCD_RST_PIN  | GP4                        | RES     |
| LCD_DC_PIN   | GP6                        | DC      |
| LCD_CS_PIN   | GP5                        | CS      |
| LCD_BLK_PIN  | GP10                       | BLK     |
| SPI_SCK_PIN  | GP2                        | SCL     |
| SPI_MOSI_PIN | GP3                        | SDA     |

### `mcuconf.h` 

参考にしたサイトでは `mcuconf.h` を `config.h` と同じ場所に作成して以下の設定を書くよう示されていますが、私が試した限りでは `mcuconf.h` が無くても大丈夫みたいです。なお、以下の設定は参考にしたサイトのコードをそのままコピペしていますので、上の設定を踏まえるなら "SPI1" は "SPI0" になります。

```c
/* mcuconf.h */

#pragma once

#include_next <mcuconf.h>

#undef RP_SPI_USE_SPI1
#define RP_SPI_USE_SPI1 TRUE

#undef RP_PWM_USE_PWM3
#define RP_PWM_USE_PWM3 TRUE
```

### `halconf.h` 

SPI 通信を使うため、`halconf.h` を `config.h` と同じ場所に作成して以下の設定を追加します（公式リファレンスの [ChibiOS/ARM Configuration](https://docs.qmk.fm/drivers/spi#arm-configuration) 参照）。

```c
/* halconf.h */

#define HAL_USE_SPI TRUE
#define SPI_USE_WAIT TRUE
#define SPI_SELECT_MODE SPI_SELECT_MODE_PAD
```

これはマイコンが ARM の場合の設定ですので、マイコンが AVR の場合の設定は公式リファレンスの [AVR Configuration](https://docs.qmk.fm/drivers/spi#avr-configuration) で確認してください。

### LCD に表示する画像の作成

次は LCD に表示する画像を作成します。大まかな手順は次のとおりです。

- 画像を保存するディレクトリを作成します。
- 表示したい画像をディレクトリに保存します
- 画像のサイズを LCD の解像度に合わせて 240x240 にします
- `qmk painter-convert-graphics` コマンドで画像を QMK 対応形式（`.qgf`）に変換します。
- `rules.mk` に変換した画像を使うための設定を追加します。

`keyboards/test/images/icon.png` を16色の `.qgf` ファイルに変換して同じディレクトリに保存するコマンドは次のとおりです。なお、256色とか65536色の画像にも変換できますが、試した限りでは、16色で必要充分かなと思います。高画質にするほどファームウェアの容量も大きくなりますので、適宜調整してください。

```bash
qmk painter-convert-graphics -f pal16 -v -i keyboards/test/images/icon.png
```

このコマンドを実行すると `images/` ディレクトリに `icon.qgf.h` と `icon.qgf.c` が生成されます。画像を変換したら、変換した `.qgf` ファイルを QMK で使うため `rules.mk` に設定します。

```make
# rules.mk

SRC += images/icon.qgf.c
```

使いたい画像が複数ある場合、上記の手順を必要なだけ繰り返します。

なお、`painter-convert-graphics` コマンドのオプションは `qmk painter-convert-graphics --help` で確認できます。

### LCD に画像を表示するための設定

これでようやく事前準備ができましたので、実際に LCD に画像を表示する処理を書いていきます。

LCD に画像を表示する処理は `keymap.c` に書けますが、`keymap.c` には本来のキーマップの処理だけを書きたいので、`test_color_lcd.c` ファイルを作成してそこに書くことにしました。なお、`test_color_lcd.c` というファイル名は、このカラー LCD のテストをするためのキーボード名を便宜的に "test_color_lcd" にしているためです。

画像を表示するコードは以下のとおりです。簡単な説明はコメントに書いていますが、この後で細かい説明を追記します。なお、このコードは、9つの画像をキー操作に応じて切り替えるという動作を実現するためのものです。

```c
/* test_color_lcd.c */

// LCD に表示するための API を使うためのインクルード
#include <qp.h>

// LCD に表示する画像のヘッダファイルをインクルードします
#include "images/blender.qgf.h"
#include "images/clipstudio.qgf.h"
#include "images/excel.qgf.h"
#include "images/fusion360.qgf.h"
#include "images/illustrator.qgf.h"
#include "images/kicad.qgf.h"
#include "images/photoshop.qgf.h"
#include "images/qmk.qgf.h"
#include "images/steam.qgf.h"

// コードから LCD を扱うための変数を用意します
// この後の dip_switch_update_mask_kb() でも使うのでグローバル変数にしています
painter_device_t lcd;

// コードから LCD に表示する画像を扱うための変数を用意します
// この後の dip_switch_update_mask_kb() でも使うのでグローバル変数にしています
painter_image_handle_t blender_logo;
painter_image_handle_t clipstudio_logo;
painter_image_handle_t excel_logo;
painter_image_handle_t fusion360_logo;
painter_image_handle_t illustrator_logo;
painter_image_handle_t kicad_logo;
painter_image_handle_t photoshop_logo;
painter_image_handle_t qmk_logo;
painter_image_handle_t steam_logo;

// キーボード初期化の最終処理の段階で LCD を描画する
void keyboard_post_init_kb(void) {
  // LCD を定義します
  lcd = qp_gc9a01_make_spi_device(
      LCD_HEIGHT,
      LCD_WIDTH,
      LCD_CS_PIN,
      LCD_DC_PIN,
      LCD_RST_PIN,
      LCD_SPI_DIVISOR,
      SPI_MODE
  );

  // LCD を初期化します
  qp_init(lcd, LCD_ROTATION);

  // LCD のオフセット位置を指定します
  qp_set_viewport_offsets(lcd, LCD_OFFSET_X, LCD_OFFSET_Y);

  // LCD をオンにします
  qp_power(lcd, true);

  // .qgfファイルの画像を変数に格納します
  blender_logo = qp_load_image_mem(gfx_blender);
  clipstudio_logo = qp_load_image_mem(gfx_clipstudio);
  excel_logo = qp_load_image_mem(gfx_excel);
  fusion360_logo = qp_load_image_mem(gfx_fusion360);
  illustrator_logo = qp_load_image_mem(gfx_illustrator);
  kicad_logo = qp_load_image_mem(gfx_kicad);
  photoshop_logo = qp_load_image_mem(gfx_photoshop);
  qmk_logo = qp_load_image_mem(gfx_qmk);
  steam_logo = qp_load_image_mem(gfx_steam);

  // blender_logo を X=0 Y=0 の位置に描画します
  qp_drawimage(lcd, 0, 0, blender_logo);

  // LCD の表示を更新します
  qp_flush(lcd);
}
```

以下ではもう少し細かい説明を書いていきます。

#### #include "images/blender.qgf.h"

キーボードが起動した時点では表示しない画像までインクルードしているのは、キー操作に応じて画像を切り替える処理の中で画像を動的に読み込んだら LCD がフリーズしたためです。おそらく、メモリ容量の限界にぶつかったのではないかと思います。QMK の `qp_close_image()` 関数で読み込んだ画像を解放しながら動的に画像を読み込めばメモリの問題は回避できると思いますが、その処理を書くのが面倒だったので、最初の段階で全ての画像を読み込むようにしました。

#### keyboard_post_init_kb()

キーボード初期化の最後の段階で LCD の設定をしていますが、初期化の最後の段階で何か処理するのであれば `keyboard_post_init_user()` に書いてもOKです。私は公式リファレンスが `keyboard_post_init_kb` に処理を書いていたので、同様にしています。

#### qp_gc9a01_make_spi_device

LCD を定義する関数で、この関数は GC9A01 用です。公式リファレンスに LCD のドライバ毎にどの関数を使うかが説明されていますので、自分が使うドライバに合った関数を使います。

#### qp_load_image_mem()

LCD に表示する画像を変数に格納する関数です。引数は、`.qgf.c` で定義されている画像データの定数です。

#### qp_flush(lcd)

`qp_drawimage(lcd, 0, 0, blender_logo)` で画像を描画しても、`qp_flush()` 関数を実行しないと LCD の表示が更新されません。そのため、`qp_drawimage()` と `qp_flush()` はセットで使う必要があります。

### キー操作に応じて画像を切り替える

上記の設定でキーボード起動後に LCD に画像が表示されるようになりますが、画像1枚を表示するだけでは面白くないので、キーを押す度に画像が切り替わる設定を `keymap.c` に追加します。上で説明した画像表示の応用なので、処理の説明はコメントを参照してください。

実際の動作は次の動画のとおりです。

<video class="video-shortcode" preload="auto" controls>
  <source src="https://github.com/s-show/s-show.github.io/raw/refs/heads/master/content/posts/2024-10-14/image/change_image.MP4">
</video>

```c
/* keymap.c */

#include QMK_KEYBOARD_H

// test_color_lcd.c で定義したグローバル変数を利用します
extern painter_device_t lcd;
extern painter_image_handle_t blender_logo;
extern painter_image_handle_t clipstudio_logo;
extern painter_image_handle_t excel_logo;
extern painter_image_handle_t fusion360_logo;
extern painter_image_handle_t illustrator_logo;
extern painter_image_handle_t kicad_logo;
extern painter_image_handle_t photoshop_logo;
extern painter_image_handle_t qmk_logo;
extern painter_image_handle_t steam_logo;

// 画像切り替え用のキーコードを定義します
enum custom_keycodes {
  QWERTY = SAFE_RANGE,
  forward,
  back
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  [0] = LAYOUT( forward, back )
};

// キータイプ毎に実行される process_record_user() に画像切り替え処理を書きます
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  // キーを押した回数を保存する変数を静的変数として宣言
  static uint16_t counter = 0;
  switch (keycode) {
    case forward:
      // 画像切り替えをループさせるための条件分岐
      if (record->event.pressed) {
        if (counter < 8) {
          counter++;
        }
        else {
          counter = 0;
        }
        switch (counter) {
          case 0:
            qp_drawimage(lcd, 0, 0, blender_logo);
            qp_flush(lcd);
            break;
          case 1:
            qp_drawimage(lcd, 0, 0, clipstudio_logo);
            qp_flush(lcd);
            break;
          case 2:
            qp_drawimage(lcd, 0, 0, excel_logo);
            qp_flush(lcd);
            break;
          case 3:
            qp_drawimage(lcd, 0, 0, fusion360_logo);
            qp_flush(lcd);
            break;
          case 4:
            qp_drawimage(lcd, 0, 0, illustrator_logo);
            qp_flush(lcd);
            break;
          case 5:
            qp_drawimage(lcd, 0, 0, kicad_logo);
            qp_flush(lcd);
            break;
          case 6:
            qp_drawimage(lcd, 0, 0, photoshop_logo);
            qp_flush(lcd);
            break;
          case 7:
            qp_drawimage(lcd, 0, 0, qmk_logo);
            qp_flush(lcd);
            break;
          case 8:
            qp_drawimage(lcd, 0, 0, steam_logo);
            qp_flush(lcd);
            break;
        }
      }
      break;
  case back:
      if (record->event.pressed) {
        if (counter > 0) {
          counter--;
        }
        else {
          counter = 8;
        }
        switch (counter) {
          case 0:
            qp_drawimage(lcd, 0, 0, blender_logo);
            qp_flush(lcd);
            break;
          case 1:
            qp_drawimage(lcd, 0, 0, clipstudio_logo);
            qp_flush(lcd);
            break;
          case 2:
            qp_drawimage(lcd, 0, 0, excel_logo);
            qp_flush(lcd);
            break;
          case 3:
            qp_drawimage(lcd, 0, 0, fusion360_logo);
            qp_flush(lcd);
            break;
          case 4:
            qp_drawimage(lcd, 0, 0, illustrator_logo);
            qp_flush(lcd);
            break;
          case 5:
            qp_drawimage(lcd, 0, 0, kicad_logo);
            qp_flush(lcd);
            break;
          case 6:
            qp_drawimage(lcd, 0, 0, photoshop_logo);
            qp_flush(lcd);
            break;
          case 7:
            qp_drawimage(lcd, 0, 0, qmk_logo);
            qp_flush(lcd);
            break;
          case 8:
            qp_drawimage(lcd, 0, 0, steam_logo);
            qp_flush(lcd);
            break;
        }
      }
      break;
  return true;
}
```

## 参考にしたサイト

- [Quantum Painter | QMK Firmware](https://docs.qmk.fm/quantum_painter)
- [SPI Master Driver | QMK Firmware](https://docs.qmk.fm/drivers/spi)
- [[自作キーボード]QMKファームウェアでカラーLCDに対応する～基本編～ - QUEFRENCY](https://quefrency.net/post/2023-10-26_1/)
- [Quantum Painter tutorial](https://kbd.news/Quantum-Painter-tutorial-2336.html)
- [OakNinja - qmk_firmware](https://github.com/OakNinja/qmk_firmware/tree/master/keyboards/qp_display_only)
