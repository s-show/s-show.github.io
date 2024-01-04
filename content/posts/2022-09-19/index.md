---
# type: docs 
title: スライサーの設定で Pressure_advance の設定値を変更する方法
date: 2022-09-19T10:28:27+09:00
featured: false
draft: false
comment: true
tags: [3Dプリンタ]
---


## 前置き

プリントヘッドの移動に合わせてフィラメントの押出量を調整する [Pressure advance](https://www.klipper3d.org/Kinematics.html#pressure-advance) 機能を使う場合、必要な設定値を `printer.cfg` に `pressure_advance: 0.045` の形式で設定する必要があります。しかし、この設定値は、フィラメント毎、印刷温度毎に変化しますので、最低でもフィラメントを切り替える都度 `printer.cfg` を編集する必要が生じます。

これは結構面倒ですが、幸い、スライサーの設定を変更することでフィラメント毎に設定値を変更する方法を教えてもらいましたので、備忘録としてまとめます。

ちなみに、教えてもらった場は 3Dプリンタ愛好家の方々が集まっている Discord のサーバーの Klipper_jp で、教えていただいた方は [show555（@show555）さん / Twitter](https://twitter.com/show555) です。

## 方法

この方法は、PrusaSlicer または SuperSlicer で実施できます。具体的な方法はどちらのスライサーでも同じです。

まず、それぞれのスライサーの設定画面の「フィラメント設定 (Filament Settings) 」を開き、次に「カスタムGコード (Custom G-code) 」を開きます。そして、「Gコードの最初 (Start G-code) 」に次のコードを追加します。コードを追加したら、このプリセットを保存し、モデルをスライスします。

```
{if physical_printer_preset == "Fluiddpi_Ender3"}SET_PRESSURE_ADVANCE ADVANCE=0.05{endif}
{if physical_printer_preset == "Prusa MK3S+ with Klipper"}SET_PRESSURE_ADVANCE ADVANCE=0.05{endif}
```

{{< bsimage src="image01.png" title="PrusaSlicer の場合" >}}
{{< bsimage src="image02.png" title="SuperSlicer の場合" >}}

このコードの内容は次のとおりです。

まず、`{if physical_printer_preset == "Fluiddpi_Ender3"}` の部分は、使うプリンタの名前が `Fluiddpi_Ender3` であるかどうかを `if` 文で判定しています。そして、判定結果が真であれば、`SET_PRESSURE_ADVANCE ADVANCE=0.05` Gコードをスライスして生成した Gコードに印刷開始前の部分に埋め込みます。これにより、`printer.cfg` を編集することなくフィラメントに応じた設定値が印刷に適用されるようになります。最後の `{endif}` は、`if` 文終了のコードです。

ここで使うプリンタ名は、「物理プリンターの編集 (Edit phisycal printer) 」の「プリンタの記述的な名前 (Descriptive name for the printer) 」に登録している名前です。

{{< bsimage src="image11.png" title="PrusaSlicer の場合" >}}
{{< bsimage src="image12.png" title="SuperSlicer の場合" >}}

これでモデルをスライスして生成された Gコードに `SET_PRESSURE_ADVANCE ADVANCE=0.05` が埋め込まれるようになります。

```
; Don't change E values below. Excessive value can damage the printer.
M907 E430 ; set extruder motor current
G21 ; set units to millimeters
G90 ; use absolute coordinates
M83 ; use relative distances for extrusion
; Filament gcode

SET_PRESSURE_ADVANCE ADVANCE=0.05 <-- 埋め込まれた Gコード
M107
;LAYER_CHANGE
;Z:0.2
;HEIGHT:0.2
;BEFORE_LAYER_CHANGE
G92 E0.0
```

なお、上記の `if` 文で登場する `physical_printer_preset` は、カスタム Gコードの設定で使える Placeholder です。これを使うとプリンタ名に応じて処理を切り替えられるようになります。これ以外にも、以下の公式マニュアルで色々な Placeholder が用意されていることが分かりますので、必要に応じて使い分けると便利だと思います。

[List of placeholders | Prusa Knowledge Base](https://help.prusa3d.com/article/list-of-placeholders_205643)

また、`if` 文の構文などは、以下の公式マニュアルで解説されていますので、こちらも必要に応じて参照してください。

[Macros | Prusa Knowledge Base](https://help.prusa3d.com/article/macros_1775#variables-placeholders)
