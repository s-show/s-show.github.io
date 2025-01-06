---
# type: docs 
title: QMK Firmware でオリジナルロゴを表示する方法
date: 2024-11-04T18:04:45+09:00
featured: false
draft: false
comment: true
toc: false
tags: [自作キーボード]
archives: 2024/11
---

## 前置き

2年ぶりに新しいキーボードを設計しましたが、今回は DIP スイッチや OLED を使うようにしたので、右手側の OLED にオリジナルロゴを表示したいと思いました。

試行錯誤してオリジナルロゴを表示できるようになりましたので、オリジナルロゴを表示する方法を備忘録としてまとめます。


## ロゴを表示する方法

### ロゴの作成

オリジナルロゴを表示する方法は2通りありますが、まずはロゴを作成する必要があります。ロゴを作成するときは、自分が使う OLED の解像度に合わせたサイズにする必要があります。私が使っている OLED は 128x32 の解像度なので、ロゴも同じ大きさで以下のとおり作成しました。

{{< bsimage src="./image/screenshot_logo_bmp.png" title="表示したいロゴ" >}}

ロゴが完成したら、ロゴを QMK Firmware が扱える形式に変換して表示しますが、変換・表示の方法は2つあるため、それぞれの方法を紹介します。


### 変換したロゴを `keymap.c` に追加して画像として表示

オリジナルロゴの画像データを OLED で扱えるバイト列に変換し、そのバイト列を `keymap.c` ファイルに追加して QMK Firmware の API を使って画像として OLED に表示するという方法です。変換した画像データを `keymap.c` に追加して API で表示するだけなので、作業としてはこちらの方が楽です。

まず、オリジナルロゴを OLED で扱えるバイト列に変換する必要がありますが、変換には [image2cpp](https://javl.github.io/image2cpp/) を使います。

[image2cpp](https://javl.github.io/image2cpp/) を開いたら、「1. Select image」のファイル選択でオリジナルロゴの画像データをアップロードします。それから以下のスクリーンショットの通りパラメータを設定して「Generate code」ボタンをクリックします。するとテキストエリアに変換されたバイト列が表示されますので、それを OLED にロゴを表示する処理を行うユーザー関数（ここでは `render_logo()`）にセットします。

{{< bsimage src="./image/screenshot_image2cpp.png" title="image2cpp のパラメータなど" >}}

```c
// keymap.c
static void render_logo(void) {
    static const unsigned char PROGMEM raw_logo[] = {
        // 変換したデータを `raw_logo[]` の値にセットします
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x30, 0x0c, 0x02, 0x03, 0x02, 0x0c, 0x30,
        ...
        0x00, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x10, 0x20, 0x20, 0x20, 0x10, 0x3f, 0x00, 0x00, 0x00, 0x00
    };
    oled_write_raw_P((const char *)raw_logo, sizeof(raw_logo));
}
```

そして OLED の制御を担当する `oled_task_user()` 関数から `render_logo()` 関数を呼び出します。ここでは `is_keyboard_left()` 関数を使って右手側の OLED にのみロゴを表示するようにしています。

```c
// keymap.c
bool oled_task_user(void) {
    if (!is_keyboard_left()) {
        render_logo();
    } else {
        // 左手側の OLED の制御処理
    }
    return false;
}
```

これでソースコードの編集は完了しましたので、ファームウェアをビルドします。ビルドしたファームウェアは左右それぞれのマイコンに書き込みます。キーマップの変更とは異なり、OLED の表示を変更する場合、左右それぞれのマイコンに新しいファームウェアを書き込む必要があるようです。

これで以下の写真のようにオリジナルロゴが表示されます。

{{< bsimage src="./image/logo1.jpeg" title="OLED に表示されたロゴ" >}}


### `glcdfont.c` のロゴ画像の部分を差し替える方法

QMK Firmware がデフォルトで使っている `glcdfont.c` には「英数字・記号・ロゴ」の3つのデータが含まれていますが、このうち、ロゴの部分をオリジナルロゴに差し替えて表示するという方法です。

もう少し具体的に説明しますと、QMK Firmware が OLED に文字列を表示する場合、`glcdfont.c` の中から1文字ずつ対応するデータを取り出して順番に OLED に表示しています。以下の画像は `glcdfont.c` のデータを画像化したものですが、例えば「QMK」という文字列を表示する場合、`glcdfont.c` の81番目・77番目・75番目の文字を順番に表示して「QMK」という文字列を表示しています。

{{< bsimage src="./image/qmk_oled_method1.png" title="https://qiita.com/koktoh/items/3d057e747915aee814cd の画像を加工" >}}

そして、この画像の左下に QMK のロゴがありますが、`glcdfont.c` はロゴを文字の集合として表現しています。そのため、`glcdfont.c` からこの部分の文字を順番に表示すれば QMK のロゴを表示できます。

{{< bsimage src="./image/qmk_oled_method2.png" title="https://qiita.com/koktoh/items/3d057e747915aee814cd の画像を加工" >}}

公式リファレンスでロゴの表示方法として紹介されているのはこの方法で、`glcdfont.c` のロゴの部分のデータを任意のデータに差し替えればオリジナルロゴを表示できます。この方法の大まかな流れは次のとおりです。

1. `glcdfont.c` のデータを画像化したファイルを入手する
2. 1. のファイルを画像編集アプリで編集し、既存のロゴをオリジナルロゴに差し替える。
3. 2. のファイルを [QMK Logo Editor](https://joric.github.io/qle/) で変換する
4. 3. で変換したデータを使ってオリジナルの `glcdfont.c` を作成して適当な場所に保存する
5. `config.h` で 4. の `glcdfont.c` を使うように設定する

まず、`glcdfont.c` のデータを画像化した上記のファイルが必要ですが、[QMK Logo Editor](https://joric.github.io/qle/) にアクセスして「Download Image」をクリックすれば以下の画像が入手できます（QMK Firmware に上記のファイルは含まれていないようです）。上の画像と少し異なりますが、今回の目的を果たす上では違いは無視できます（上の画像は説明のために文字の間に区切りを追加したものです）。

{{< bsimage src="./image/qmk_logo_editor_image.png" title="QMK Logo Editor からダウンロードした画像" >}}

画像ファイルを入手したら、画像編集アプリを使って下の画像の赤枠の部分をオリジナルロゴに差し替えます。なお、この赤枠の部分のサイズは 125x24 ピクセルなので、最初に作ったロゴ（128x32）に差し替えるには画像を縮小する必要があります。

{{< bsimage src="./image/qmk_logo_editor_image_notation.png" title="オリジナルロゴに差し替える部分" >}}

差し替え後の画像は以下のとおりです。実際に編集するときは、赤枠内の差し替えた画像の線をもう少し修正する必要があると思います。

{{< bsimage src="./image/qmk_logo_editor_image_after_edit.png" title="編集後の画像" >}}

画像の編集が完了したら、[QMK Logo Editor](https://joric.github.io/qle/) に再びアクセスして「Font」タブの「Upload Image」をクリックして編集後のファイルをアップロードします。すると、表示されている画像がアップロードしたものに変更され、テキストエリアにアップロードした画像をバイト列に変換した結果が表示されます。

{{< bsimage src="./image/qmk_logo_editor_after_upload.png" title="アップロード後の画面" >}}

変換結果が表示されたら、QMK Firmware の `drivers/oled/glcdfont.c` をロゴを表示したいキーボードのディレクトリ（ここでは `keyboards/yamanami_cherry`）にコピーして、`static const unsigned char font[] PROGMEM = {}` の中身を変換結果に置き換えます。

```c
// glcdfont.c
static const unsigned char font[] PROGMEM = {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xC1, 0xA4, 0xB0, 0xA4, 0xC1, 0xFF,
    ...
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
};
```

それから、`config.h` に以下の設定を追加して、`drivers/oled/glcdfont.c` の代わりに `keyboards/yamanami_cherry/glcdfont.c` を使うよう設定します。

```c
// config.h
#define OLED_FONT_H "keyboards/yamanami_cherry/glcdfont.c"
```

そして、`keymap.c` に以下のコードを追加します。

```c
// keymap.c
static void render_logo(void) {
    static const char PROGMEM qmk_logo[] = {
        // ロゴの部分のインデックスを指定しています
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F, 0x90, 0x91, 0x92, 0x93, 0x94,
        0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4,
        0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0x00
    };
    oled_write_P(qmk_logo, false);
}

bool oled_task_user(void) {
    render_logo();
    return false;
}
```

あとはファームウェアをビルドして左右それぞれのマイコンに書き込めば、オリジナルロゴが OLED に表示されるはずです。`glcdfont.c` に合わせるため縮小したこともあり、先程のロゴと形が少し変わっています。

{{< bsimage src="./image/logo2.jpeg" title="OLED に表示されたロゴ" >}}

なお、この方法は「`glcdfont.c` のロゴの部分を順番に取り出して表示する」という方法ですので、上記の `qmk_logo[]` の内容を変えるとロゴの表示が壊れます。試しに、上記のコードの `0xC0` の行を1行目に移動させて以下のコードのようにすると、写真のとおり OLED 下側の「Keyboard」という文字列のラインが上に移動して表示が壊れています。

```c
// keymap.c
static void render_logo(void) {
    static const char PROGMEM qmk_logo[] = {
        0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4,
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F, 0x90, 0x91, 0x92, 0x93, 0x94,
        0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0x00
    };
    oled_write_P(qmk_logo, false);
} // 以下同じ
```

{{< bsimage src="./image/broken_logo.jpeg" title="表示が壊れたロゴ" >}}

## 補足

### 2つの方法の使い分け

ロゴを表示する方法として2つの方法を紹介しましたが、この2つの方法を比較すると次のような感じになると思いますので、これを参考にしてどちらを採用するか検討すれば良いと思います。

|                                | 作業量 | 使える画像サイズ   |
|--------------------------------|--------|--------------------|
| ロゴを画像として表示する方法   | 少ない | OLED の解像度と同じ |
| ロゴを文字列として表示する方法 | 多い   | 125x24             |


## 参考にしたサイト

- [OLED Driver | QMK Firmware](https://docs.qmk.fm/features/oled_driver)
- [QMK の OLED 基礎知識 #oled - Qiita](https://qiita.com/koktoh/items/3d057e747915aee814cd)
- [QMK FirmwareでOLEDに好きな画像を映す](https://zenn.dev/takashicompany/articles/e2c0aec4465f95)
- [MakotoKurauchi/helix - Doc/firmware_jp.md](https://github.com/MakotoKurauchi/helix/blob/master/Doc/firmware_jp.md#%E3%83%95%E3%82%A9%E3%83%B3%E3%83%88%E3%83%87%E3%83%BC%E3%82%BF%E3%81%AE%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%9E%E3%82%A4%E3%82%BA)
