---
# type: docs 
title: QMK Firmware で Alt-tab を実現する方法
date: 2024-01-04T01:51:48+09:00
featured: false
draft: false
comment: true
toc: true
tags: [備忘録,自作キーボード]
---

## 前置き

1キーで Alt-Tab の動作を実現したいと以前から思っていましたが、上手い実装方法が見つからず断念していました。ところが、先日あらためて実装方法を探してみるとあっさり実装方法が見つかりましたので、早速導入してみました。

この方法は癖が強いものの慣れれば結構快適な動作なので、その方法を備忘録代わりにまとめます。

## 必要なコード

まずはこの処理の実装コードを掲載します。処理の流れなどはコードの後に説明します。

```c
bool is_alt_tab_active = false;    // ADD this near the begining of keymap.c
uint16_t alt_tab_timer = 0;        // we will be using them soon.

enum custom_keycodes {
  QWERTY = SAFE_RANGE,
  ALT_TAB
};

// ALT_TAB キーのキーマップへの割り当てコードは省略

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {
    case ALT_TAB:
      if (record->event.pressed) {
        if (!is_alt_tab_active) {
          is_alt_tab_active = true;
          register_code(KC_LALT);
        }
        alt_tab_timer = timer_read();
        register_code(KC_TAB);
      } else {
        unregister_code(KC_TAB);
      }
      break;
    case KC_RIGHT: case KC_LEFT: case KC_DOWN: case KC_UP: case KC_TAB:
      if (is_alt_tab_active) {
        alt_tab_timer = timer_read();
      }
      break;
    default:
      if (is_alt_tab_active) {
        unregister_code(KC_LALT);
        is_alt_tab_active = false;
      }
      break;
  }
  return true;
}

void matrix_scan_user(void) {
  if (is_alt_tab_active && timer_elapsed(alt_tab_timer) > 1000) {
    unregister_code(KC_LALT);
    is_alt_tab_active = false;
  }
}

```

## 動作の流れ

動作の流れは次のとおりです。コードを見れば分かる方は無視してください。

1. `keymap.c` に `bool is_alt_tab_active = false` 変数を定義して、Alt-tab 処理を実現している最中か判別するためのフラグを用意する
2. `keymap.c` に `uint16_t alt_tab_timer = 0` 変数を定義して、Alt-tab 処理を開始した時間を記録できるようにする
3. キーマップに専用のキー（ここでは `ALT-TAB` ）を割り当てる
4. `process_record_user` 内の `switch` 文に `ALT-TAB` に対応する `case` 文を追加する
5. `ALT-TAB` が押されて、かつ `is_alt_tab_active` 変数が `false` であれば、`is_alt_tab_active` 変数を `true` にする
7. `register_code(KC_LALT)` で Alt キーを押した状態を実現する
8. `alt_tab_timer = timer_read()` で `ALT-TAB` キーを押した時間を記録する
9. `register_code(KC_TAB)` で Tab キーを押した状態を実現する
10. `ALT-TAB` キーが離されたら、`unregister_code(KC_TAB)` で Tab キーを離した状態にする
11. `matrix_scan_user` で `is_alt_tab_active` 変数が `true` かつ `ALT-TAB` キーを押してから 1000ミリ秒が経過（`timer_elapsed(alt_tab_timer) > 1000` を満たす場合）していた場合、`unregister_code(KC_LALT)` で Alt キーを離した状態にするとともに、`is_alt_tab_active = false` でフラグを下ろす。 
12. もし、`is_alt_tab_active` 変数が `true` のときに上下左右の矢印キーが押された場合、`alt_tab_timer` をその時点の時間に置き換えてウィンドウ選択の時間を確保できるようにする。
13. もし、`is_alt_tab_active` 変数が `true` のときに上下左右の矢印キー**以外**が押された場合、`unregister_code(KC_LALT)` で Alt キーを離した状態にするとともに、`is_alt_tab_active = false` でフラグを下ろす（Enterキーでウィンドウを選択した場合を想定した設定）。

## 補足

1キーで Alt-Tab を実現している以上、Alt キーを押しながらのんびり Tab キーを押してウィンドウを選択するという処理はできません。そのため、一回該当するキーを押したら、速やかにカーソルキーで移動先のウィンドウを選択する必要があります。

私の場合、ホームポジションから手を動かさずにレイヤー移動でカーソルキーにアクセスできるので上記の制限は問題にならないのですが、手を動かさないとカーソルキーにアクセスできない場合はちょっと問題になるかもしれません。 

## 参考資料

上記のコードの元ネタのファイルは https://github.com/qmk/qmk_firmware/pull/22695 のプルリクで削除されているので、削除前のファイルへのリンクを掲載
https://github.com/qmk/qmk_firmware/blob/d235352504f82eae5dedc399bae36c65f1348fa8/keyboards/dz60/keymaps/_bonfire/not-in-use/super-alt-tab.c