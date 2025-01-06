---
# type: docs
title: QMK Firmware で1つのキーに Hold/Double Tap を割り当てる方法
date: 2022-09-18T15:00:00+09:00
draft: false
comment: true
tags: [自作キーボード]
archives: 2022/09
---

## 長い前置き

私はキー数が右手側・左手側 24 キーずつの合計 48 キーの自作キーボードを使っているのですが、IME の切り替えは、Windows の標準的なトグル式ではなく、Mac のように IME をオンにするキーとオフにするキーを別々に用意する形にしています。

この IME 切り替えキーの置き場所にいつも悩んでいるのですが、一番の希望先は親指周りのキーで、左手側のキーボードには IME オフのキーを、右手側のキーボードには IME オンのキーを割り当てて左右対称のキーマップにして、キーマップを覚えやすくしたいと思っています。

しかし、私のキーボードは親指周りに 8 キーありますが、ここに `Win（左右）`, `Alt（左右）`, `Space（左手）`, `Backspace（右手）`, `lower（左手）`, `raise（右手）` の 6 種類を割り当てる必要があるため、空きが無い状態となっています。そのため、1 つのキーに一人二役を担わせる必要があるのですが、それができるのは以下のとおり `lower/raise` キーぐらいという状態です。

`Win`
: 単押しとホールドの両方行うので、二つ目の役割は二連打に割り当てることになる。

`Alt`
: 単押しとホールドの両方行うので、二つ目の役割は二連打に割り当てることになる。

`Backspace`
: 単押しと連打とホールドを行うので、二つ目の役割を担わせるのは不可能。

`Space`
: 単押しと連打とホールドを行うので、二つ目の役割を担わせるのは不可能。

`lower`
: ホールドのみなので、単打か二連打に別の処理を割り当て可能。

`raise`
: ホールドのみなので、単打か二連打に別の処理を割り当て可能。

そこで `lower/raise` キーに一人二役を担ってもらうのですが、単打とホールドを同じキーに割り当てる方法は既に編み出されています。

[QMK Firmware で Raise/Lower と変換/無変換を同じキーに割り当てる - Okapies' Archive](https://okapies.hateblo.jp/entry/2019/02/02/133953)

私もこの方法を採用していたのですが、キーボードのキー数が 48 キーなので、記号・数字の入力や矢印キーを使うときに `LOWER/RAISE` レイヤーに移動する必要があり、その時のタイピングミスでレイヤー移動（ホールド）のつもりが IME 切り替え（単打）になることがちょくちょくありました。これはかなりストレスになるので、やむなくこの方法を断念して[コンボ](https://docs.qmk.fm/#/ja/feature_combo)機能を使って `JK` 同時押しに IME オン、`DF` 同時押しに IME オフを割り当てていましたが、IME 切り替えのために 2 つのキーを同時押しするのもイマイチという印象を感じていました。

そうした中、私が最初の翻訳を手掛けた[タップダンス](https://docs.qmk.fm/#/ja/feature_tap_dance)機能の解説の中に、1 つのキーに 4 つの機能を持たせるというものがあり、ホールドとダブルタップ（二連打）に別々の処理が割り当てられていたことを思い出しました。

<dl>
  <dt>
    4つの機能とその入力方法
  </dt>
  <dd>
    <ul>
      <li> 1回タップ = <code>x</code> を送信</li>
      <li> 押し続ける = <code>Control</code> を送信</li>
      <li> 2回タップ = <code>Escape</code> を送信</li>
      <li> 2回タップして押し続ける = <code>Alt</code> を送信</li>
    </ul>
  </dd>
</dl>

この方法でホールドにレイヤー移動を割り当ててダブルタップに IME 切り替えを割り当てようと思ったのですが、処理が結構複雑だったので、ホールドと単打の使い分けの方法を応用してもっと処理を簡単にできないかと思い、一応希望する動作を実現できたので、備忘録としてどんな処理にしたのかをまとめます。

## 実際のコード

ホールドとダブルタップの判定は、キーを押す度に実行される `process_record_user` 関数の中で実施します。ただし、最初のタップ時に立てるフラグ (`first_lower/raise_pressed`) とキーを押した時間を格納する変数 (`first_lower/raise_pressed_time`) は、`process_record_user` 関数を終了しても状態を保存する必要がありますので、関数の外でグローバル変数として定義しています。

処理の内容は以下のコードのとおりですが、補足情報をコメントで書き込んでいます。

```c
static bool first_lower_pressed = false;
static uint16_t first_lower_pressed_time = 0;
static bool first_raise_pressed = false;
static uint16_t first_raise_pressed_time = 0;

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {
    case LOWER:
      if (record->event.pressed) {
        if (!first_lower_pressed) {
          first_lower_pressed_time = record->event.time;
        // 一回目のタップのフラグがオン & 最初のキー押下から2回目のキー押下までの時間が TAPPING_TERM の2倍超なら
        // 間隔を空けた2回目のタップと判断する
        } else if (first_lower_pressed && (TIMER_DIFF_16(record->event.time, first_lower_pressed_time) > TAPPING_TERM * 2)) {
          first_lower_pressed_time = record->event.time;
          first_lower_pressed = false;
        }
        layer_on(_LOWER);
        update_tri_layer(_LOWER, _RAISE, _ADJUST);
      } else {
        layer_off(_LOWER);
        update_tri_layer(_LOWER, _RAISE, _ADJUST);
        // タップのフラグがオフ & 最初のキー押下からキーを離した時までの時間が TAPPING_TERM 未満なら
        // タップと判断する
        if (!first_lower_pressed && (TIMER_DIFF_16(record->event.time, first_lower_pressed_time) < TAPPING_TERM)) {
          first_lower_pressed = true;
        // タップのフラグがオン & 最初のキー押下から2回目のタイプでキーを離した時までの時間が TAPPING_TERM の2倍以下なら
        // ダブルタップと判断する
        } else if (first_lower_pressed && (TIMER_DIFF_16(record->event.time, first_lower_pressed_time) <= TAPPING_TERM * 2)) {
          tap_code(KC_LANG2);
          first_lower_pressed = false;
        } else {
          first_lower_pressed = false;
        }
      }
      return false;
      break;
    case RAISE:
      if (record->event.pressed) {
        if (!first_raise_pressed) {
          first_raise_pressed_time = record->event.time;
        } else if (first_raise_pressed && (TIMER_DIFF_16(record->event.time, first_raise_pressed_time) > TAPPING_TERM * 2)) {
          first_raise_pressed_time = record->event.time;
          first_raise_pressed = false;
        }
        layer_on(_RAISE);
        update_tri_layer(_LOWER, _RAISE, _ADJUST);
      } else {
        layer_off(_RAISE);
        update_tri_layer(_LOWER, _RAISE, _ADJUST);
        if (!first_raise_pressed && (TIMER_DIFF_16(record->event.time, first_raise_pressed_time) < TAPPING_TERM)) {
          first_raise_pressed = true;
        } else if (first_raise_pressed && (TIMER_DIFF_16(record->event.time, first_raise_pressed_time) <= TAPPING_TERM * 2)) {
          tap_code(KC_LANG1);
          first_raise_pressed = false;
        } else {
          first_raise_pressed = false;
        }
      }
      return false;
      break;
  }
  first_lower_pressed = false;
  first_raise_pressed = false;
  return true;
}
```

## 終わり

これで `lower/raise` キーのホールドにレイヤー移動機能を、ダブルタップに IME 切り替えの機能を持たせることができるようになりました。

ダブルタップに処理を割り当てた場合、タイピングミスでレイヤー移動のつもりが IME 切り替えになってしまうという事態はまず発生しませんので、快適に入力できるようになりました。

本記事がどなたかの参考になれば幸いです。
