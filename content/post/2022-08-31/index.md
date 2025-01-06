---
title: "Klipper のマクロを使って Step by step 印刷を実現する方法"
date: 2022-08-30T20:27:31+09:00
draft: false
tags: [3Dプリンタ, Klipper, Mainsail]
archives: 2022/08
---


# 前置き

2022年8月18日に3Dプリンタユーザーが集まっている Discord のサーバーの klipper_jp で「GCode をスタートボタンを押して1行ずつ実行する方法はないか」という質問がありました。

そこで、1行ずつ実行する方法を調べたのですが、その過程でレイヤー切り替え毎に手動で一時停止・印刷再開を行う方法を編み出せましたので、誰かの参考になればと思い方法をまとめました。

# 必要な手順の概要

1. `printer.cfg` に [save_variables](https://www.klipper3d.org/Config_Reference.html#save_variables) セクションを追加して一時停止フラグを格納するファイルのファイル名を指定する
2. [SAVE_VARIABLE](https://www.klipper3d.org/G-Codes.html#save_variable) マクロを使って一時停止フラグのオン・オフを切り替えるマクロを `printer.cfg` に追加する
3. `PAUSE` マクロと `RESUME` マクロを定義する（定義済みならこの作業は不要）
4. 一時停止フラグの状態に応じて `PAUSE` マクロを実行するマクロを追加する 

# 実際のコード

```
#printer.cfg

[gcode_macro PAUSE]
rename_existing: BASE_PAUSE
gcode:
  SAVE_GCODE_STATE NAME=PAUSE_state
  BASE_PAUSE
  G91
  G1 E-0.5 F100
  G1 Z5
  G90
  #G1 X{X} Y{Y} F6000

[gcode_macro RESUME]
rename_existing: BASE_RESUME
gcode:
  G91
  G1 E0.5 F100
  G90
  RESTORE_GCODE_STATE NAME=PAUSE_state MOVE=1
  BASE_RESUME

[gcode_macro PAUSE_FLAG_OFF]
gcode:
  SAVE_VARIABLE VARIABLE=pause_flag VALUE=0

[gcode_macro PAUSE_FLAG_ON]
gcode:
  SAVE_VARIABLE VARIABLE=pause_flag VALUE=1

[gcode_macro ECHO_PAUSE_FLAG]
gcode:
  RESPOND MSG="PAUSE_FLAG is {printer.save_variables.variables.pause_flag}"

[gcode_macro STEP_BY_STEP_PRINT]
description: Controls step-by-step printing, pausing at each layer
gcode:
  {% if printer.save_variables.variables.pause_flag == 1 %}
  RESPOND TYPE=command MSG="PAUSE_FLAG ON"
  PAUSE
  {% else %}
  RESPOND TYPE=command MSG="PAUSE_FLAG OFF"
  {% endif %}

[save_variables]
filename: ~/variables.cfg
```

# 各処理の説明

## 一時停止フラグの準備

### フラグの格納場所

スライサーで作成した GCode にグローバル変数を埋め込むことはできないので、一時停止フラグは、Raspberry Pi のローカルファイルに格納します。

Klipper 独自の GCode には、変数をローカルファイルに書き込む[SAVE_VARIABLE](https://www.klipper3d.org/G-Codes.html#save_variable) というマクロが用意されており、ここで格納した変数は `printer.save_variables.variables.変数名` で呼び出せます。

このマクロを使うには、`printer.cfg` に[save_variables](https://www.klipper3d.org/Config_Reference.html#save_variables) セクションを追加し、変数を書き込むファイルを `filename: ~/variables.cfg` と指定する必要があります（ファイル名は任意の名前でOKだと思います）。

```
[save_variables]
filename: ~/variables.cfg
```

### フラグの切り替え

フラグを格納する場所を指定しましたので、次は `SAVE_VARIABLE` マクロを使ってフラグを立てるマクロとフラグを下ろすマクロを次のとおり作成します。なお、フラグの名前は `pause_flag` としています。

```
[gcode_macro PAUSE_FLAG_ON]
gcode:
  SAVE_VARIABLE VARIABLE=pause_flag VALUE=1

[gcode_macro PAUSE_FLAG_OFF]
gcode:
  SAVE_VARIABLE VARIABLE=pause_flag VALUE=0
```

また、現在のフラグの状態を表示するマクロがあると便利なので、そちらも用意します。

```
[gcode_macro ECHO_PAUSE_FLAG]
gcode:
  RESPOND MSG="PAUSE_FLAG is {printer.save_variables.variables.pause_flag}"
```

ここでは、引数で渡されたメッセージをコンソールに出力する[RESPOND](https://www.klipper3d.org/G-Codes.html#respond_1) マクロを使って現在のフラグの状態をコンソールに出力しています。現在のフラグの状態は `printer.save_variables.variables.pause_flag` で確認できますので、`{...}` で囲んでメッセージに埋め込んでいます。

なお、変数を `{...}` で囲む理由は、[Klipper のドキュメント](https://www.klipper3d.org/Command_Templates.html?h=jinja2#template-expansion)で次のように説明されているためです。

> Template expansion
> 
> The gcode_macro gcode: config section is evaluated using the Jinja2 template language. One can evaluate expressions at run-time by wrapping them in { } characters or use conditional statements wrapped in {% %}. See the Jinja2 documentation for further information on the syntax.

[jinja2](https://jinja.palletsprojects.com/en/2.10.x/) で変数展開するには `{...}` ではなく `{{...}}` で囲むはずなのですが、Klipper のマクロでは `{...}` で囲めば変数が展開されると書かれていますので、それに従ってコードを書いています。

### 一時停止フラグの状態に応じた条件分岐

これで一時停止フラグを切り替えられるようになりましたので、一時停止フラグの状態に応じて一時停止するか通常通り印刷するかの条件分岐を行うマクロを追加します。

マクロの `gcode:` セクションで条件分岐する場合、`if` 文は `{% ... %}` で囲みますので、コードは次のとおりとなります。

```
[gcode_macro STEP_BY_STEP_PRINT]
gcode:
  {% if printer.save_variables.variables.pause_flag == 1 %}
    RESPOND TYPE=command MSG="PAUSE_FLAG ON"
    PAUSE
  {% else %}
    RESPOND TYPE=command MSG="PAUSE_FLAG OFF"
  {% endif %}
```

`{% if printer.save_variables.variables.pause_flag == 1 %}` でフラグが立っているか確認し、フラグが立っていれば `PAUSE` マクロを実行しています。

これで `printer.cfg` 側で行う準備は完了です。

# スライサー側の設定

PrusaSlicer/SuperSlicer の「Printer Settings」の「Custom G-code」の「Before layer change g-code」に `PAUSE_FLAG_OFF` と `STEP_BY_STEP_PRINT` マクロを追加します。`PAUSE_FLAG_OFF` マクロも追加するのは、意図しない一時停止を発生させないためです。

```
;BEFORE_LAYER_CHANGE
;[layer_z]
PAUSE_FLAG_OFF
STEP_BY_STEP_PRINT
```

これで STL ファイルをスライスするだけでレイヤー切り替え直前に一時停止するかどうかの条件分岐が行われるようになりました。また、`printer.cfg` にマクロを設定したことにより、Mainsail の Macros タブに PAUSE_FLAG_ON、PAUSE_FLAG_OFF ボタンが追加されていますので、この2つのボタンでフラグを切り替えて印刷を制御します。

{{< bsimage src="image01.png" title="Macros のボタン">}}

この2つのボタンを使って印刷を制御している様子を動画にしていますので、よろしければご覧ください。

{{< youtube w3xLgyjXRJI >}}

以上で説明は完了です。

# 補足

フラグを立てる処理で `SAVE_VARIABLE VARIABLE=pause_flag VALUE=1` というコードを実行していますが、条件分岐では変数の値だけでなく型もチェックされているようですので、 `SAVE_VARIABLE VARIABLE=pause_flag VALUE=1` を実行してから次のマクロを実行した場合、コンソールには `PAUSE_FLAG is numeric 1` が表示されます。

```
[gcode_macro TEST]
gcode:
  {% if printer.save_variables.variables.pause_flag == '1' %}
    RESPOND TYPE=command MSG="PAUSE_FLAG is string '1'"
  {% endif %}
  {% if printer.save_variables.variables.pause_flag == 1 %}
    RESPOND TYPE=command MSG="PAUSE_FLAG is numeric 1"
  {% endif %}
```

また、 `SAVE_VARIABLE` マクロを使った変数のローカルファイルへの格納は、実行してから保存されるまで若干のタイムラグがあるようです。`pause_flag` の値が `0` の状態で次のコードを実行すると、コンソールに表示される値は `1` ではなく `0` になりました。

```
[gcode_macro PAUSE_FLAG_ON]
gcode:
  SAVE_VARIABLE VARIABLE=pause_flag VALUE=1
  RESPOND MSG="PAUSE_FLAG is {printer.save_variables.variables.pause_flag}"
```

そのため、`SAVE_VARIABLE` マクロを実行した直後に条件分岐のコードを追加した場合、意図した動作にならない可能性があります。
