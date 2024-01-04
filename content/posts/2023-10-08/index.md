---
# type: docs 
title: Klipper の Skew correction でプリンタの歪みによる問題を解消する
date: 2023-10-17T16:27:24+09:00
featured: false
draft: false
comment: true
toc: false
tags: [備忘録,3Dプリンタ]
---

## 前置き

我が家で稼働している Voron V0.0 で正方形の造形物を印刷したら、目で見て分かるレベルで歪みが出て平行四辺形になってしまいました。

{{< bsimage src="before_skew_correction.jpg" title="インストールするパッケージの選択" >}}

本来なら、分解して再度組み立てるべきなのですが、Voron V0.0 を組み立ては苦難の連続で再組み立ては非常に気が重いので、何とかしてソフトウェアベースで対応したいと思い、Klipper の機能である [Skew correction - Klipper documentation](https://www.klipper3d.org/Skew_Correction.html) を適用して、完全スコヤを使わなければ歪みを確認できない程度まで矯正することができました。

{{< bsimage src="after_skew_correction.jpg" title="インストールするパッケージの選択" >}}

ただ、Skew correction について解説した日本語記事が見当たらなかったので、備忘録代わりにまとめます。

## Skew correction の説明

まず、Skew correction について説明する必要がありますが、Klipper の公式リファレンスの冒頭に次の記載があります。簡単に言うと、可能な限り正確にプリンタを組み立てても生じる歪みをソフトウェアで補正するというものです。

> Software based skew correction can help resolve dimensional inaccuracies resulting from a printer assembly that is not perfectly square. Note that if your printer is significantly skewed it is strongly recommended to first use mechanical means to get your printer as square as possible prior to applying software based correction.
> 
> ソフトウェアベースの歪み訂正は、プリンタの組み立てが正確な四角形ではないことに由来する不正確な寸法を解決することを助けます。注意事項として、もし、あなたのプリンタが著しく歪んでいる場合、ソフトウェアベースの訂正を適用する前に、機械的な訂正、つまり、可能な限りプリンタを正確な四角形に組み立てることを強く勧めます。（拙訳）

## Skew correction の使い方

Skew correction を使うには、次の作業が必要です。

1. printer.cfg の編集
2. プリンタの歪みの計測
3. プリンタの歪みの計測値の保存
4. 計測値を適用するための Start G-code の編集

### printer.cfg の編集

Skew correction を使うには、まず `printer.cfg` に `[skew_correction]` セクションを追加します。

### プリンタの歪みの計測と計測値の保存

続いて、プリンタの歪みを計測して定量化します。歪みの計測と定量化する方法ですが、公式リファレンスで紹介されている方法は、計測のためのモデルを印刷して所定の3か所の距離を測り、その3か所の距離を専用の G-code の引数として与えて歪みを定量化するというものです。

専用のモデルは [YACS (Yet Another Calibration Square by Paciente8159 - Thingiverse](https://www.thingiverse.com/thing:2563185/files) で、これをプリンタのベッドの大きさに合わせて縦横比を保ったまま拡大縮小して印刷し、次の画像に示した箇所の距離を測ってメモしておきます。

{{< bsimage src="skew_lengths.png" title="https://www.klipper3d.org/Skew_Correction.html より" >}}

{{< bsimage src="model_in_slicer.png" title="モデルをスライサーにセットしたところ" >}}

次は計測した距離と G-code を使って歪みを定量化します。例えば、3か所の距離が次の値だった場合の G-code は次のとおりとなりますので、この G-code を Console に入力して実行します。

- 計測結果
  - AC間の距離: 63.97
  - BD間の距離: 63.70
  - AD間の距離: 50.22
- G-code
  - `SET_SKEW XY=63.97,63.70,50.22`<br/>
  ( '=' 以降の数値部分に空白があるとエラーになります )

これで計測した距離に基づいてプリンタの歪みを定量化できましたので、`SKEW_PROFILE SAVE=my_skew_profile` コマンドで計算結果を `my_skew_profile` というプロファイル名で保存します。なお、プロファイル名は好きな名前に設定できます。

そして、`SAVE_CONFIG` コマンドで計算結果を `printer.cfg` ファイルに保存します。これで計測値を適用する準備ができました。

### 計測値の適用

定量化したプリンタの歪みは `printer.cfg` に保存されましたが、これを印刷に適用するには `SKEW_PROFILE LOAD=my_skew_profile` G-code でロードする必要があります。

そのため、この G-code を Start G-code に登録して、印刷するたびに呼び出されるようにする必要があります。登録方法は、次の2つがあります。

- スライサーの Start G-code に登録する
- `printer.cfg` のスタートマクロに登録する

私の Start G-code は、ホットエンド加熱等の印刷準備の G-code をまとめた `PRINT_START` マクロを `printer.cfg` に追加し、このマクロをスライサーの Start G-code で呼び出す形にしていますので、2番目の方法を採用しました。

ではどのタイミングで `SKEW_PROFILE LOAD=my_skew_profile` G-code を使うかが問題になりますが、公式リファレンスの末尾の注意書き（caveats）に次の記述があります。

> Due to the nature of skew correction it is recommended to configure skew in your start gcode, after homing and any kind of movement that travels near the edge of the print area such as a purge or nozzle wipe. You may use use the `SET_SKEW` or `SKEW_PROFILE` gcodes to accomplish this. It is also recommended to issue a `SET_SKEW CLEAR=1` in your end gcode.
> Keep in mind that it is possible for `[skew_correction]` to generate a correction that moves the tool beyond the printer's boundaries on the X and/or Y axes. It is recommended to arrange parts away from the edges when using `[skew_correction]`.
>
> skew_correction の性質のために、Start G-code の中のホーミングに加えて、ノズルワイプまたはノズルパージのような造形エリアの端っこ付近での何らかの移動の後に Skew correction を設定することが推奨されています。Skew correction を達成するために `SET_SKEW` または `SKEW_PROFILE` G-code を使えます。End G-code の中で `SET_SKEW CLEAR=1` を発行することも推奨されます。
> `[skew_correction]` には、X 及び（または） Y 軸の境界を越えるツールの移動を補正として生成する可能性があることを念頭においてください。`[skew_correction]` を使う時は、造形物を印刷エリアの境界付近から遠ざける工夫を行うことが推奨されます。（拙訳）

この記述を踏まえて、私は次の箇所に `SKEW_PROFILE LOAD=my_skew_profile` と `SET_SKEW CLEAR=1` を挿入しました。`CLEAN_NOZZLE` の前にいったん `SET_SKEW CLEAR=1` で Skew correction をクリアしているのは、ノズルクリーニングがプリンタの可動範囲ギリギリで行う動作で、Skew correction を有効にして歪み補正を行うと移動先がプリンタの可動範囲の外になってエラーになるためです。

```
[gcode_macro PRINT_START]
gcode:
    SKEW_PROFILE LOAD=my_skew_profile
    G28
    {% set BED_TEMP = params.BED_TEMP|default(60)|float %}
    {% set EXTRUDER_TEMP = params.EXTRUDER_TEMP|default(210)|float %}
    M140 S{BED_TEMP}
    M190 S{BED_TEMP}
    M109 S{EXTRUDER_TEMP}

    SET_SKEW CLEAR=1
    CLEAN_NOZZLE
    Z_TILT_ADJUST
    G28
    SKEW_PROFILE LOAD=my_skew_profile

    M107
    G21 ; set units to millimeters
    G90 ; use absolute coordinates
    M83 ; use relative distances for extrusion

[gcode_macro CLEAN_NOZZLE]
variable_start_x: 270
variable_start_y: 345
variable_start_z: 4
variable_wipe_dist: -40
variable_wipe_qty: 3
variable_wipe_spd: 50
variable_raise_distance: 30
gcode:
  {% if "xyz" not in printer.toolhead.homed_axes %}
    G28
  {% endif %}
 
  ## Move nozzle to start position
  G1 X{start_x} Y{start_y} F6000
  G1 Z{start_z} F1500

  ## Wipe nozzle
  {% for wipes in range(1, (wipe_qty + 1)) %}
    G1 X{start_x + wipe_dist} F{wipe_spd * 60}
    G1 X{start_x} F{wipe_spd * 60}
  {% endfor %}

  ## Raise nozzle
  G1 Z{raise_distance}
```

これで Skew correction を適用してプリンタの歪みによって生じる印刷物の歪みを軽減できるようになりました。

本記事が何かの参考になれば幸いです。不明な点等がありましたら、コメント欄でお尋ねください。