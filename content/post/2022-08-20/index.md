---
title: "Mainsail から rotation_distance を確認・変更する方法"
date: 2022-08-19T23:58:35+09:00
draft: false
tags: [3Dプリンタ, Klipper, Mainsail]
archives: 2022/08
---


## 追記事項（2022年9月30日）

この記事を公開した時に、

> そこで `rotation_distance` の設定値を引数として渡すと `printer.cfg` の設定値を変更するシェルスクリプトは作成したのですが、これを Mainsail の CONSOLE から実行する方法が分からないため、この点は現在保留中です。正確に言うと、Mainsail の CONSOLE で複数の引数を渡す方法が分からない（できない？）ため、保留にしています。

と書いていましたが、このたび、Mainsail の Console から `rotation_distance` の設定値を変更することに成功しましたので、その方法を末尾にまとめました。

## 前置き

Klipper の設定項目の1つである `rotation_distance` は、ステッピングモーターが1回転した時の移動量を指定するものですが、フィラメント毎に調整しないと印刷物の大きさが微妙に変わってしまうため、新しいフィラメントを使う度に調整が必要になります。しかし、G-Code で設定できる `pressure_advance` とは異なり、 `rotation_distance` を調整するには毎回次の作業が必要になります。

1. `printer.cfg` ファイルの現在の設定値を確認
2. 印刷物のサイズを測る
3. 実測値と現在の設定値を基に新しい設定値を計算
4. 新しい設定値を `printer.cfg` ファイルに追加
5. Klipper 再起動という

このうち、新しい設定値の計算については、印刷物の実測値と現在の設定値から自動的に計算できる[ツール](https://codepen.io/s-show/full/NWaBVOR)を作成しているので特に面倒な作業ではないのですが、現在の設定値を確認するには、Mainsail の MACHINE タブで `printer.cfg` ファイルを開いてスクロールしながら目視で確認するか、SSH で Raspberry Pi にアクセスして `cat klipper_config/printer.cfg | grep ^rotation_distance` コマンドを実行する必要があり、正直言って面倒な作業でした。

そこで、現在の設定値を簡単に確認できる方法を探していたところ、Mainsail で任意のシェルコマンドを実行できる方法が見つかったため、早速試したところ上手くいきましたので、その方法をまとめました。

## 大まかな処理の流れ

1. KIAUH のプラグインである [G-Code Shell Command Extension](https://github.com/th33xitus/kiauh/blob/master/docs/gcode_shell_command.md) をインストール
2. `rotaton_distance` を確認するためのシェルスクリプト ( `~/get_rotation_distance.sh` ) を作成して実行権限を追加
3. `printer.cfg` に上記のシェルスクリプトを実行する GCode を追加
4. Klipper を再起動
5. Mainsail の Console で `RUN_SHELL_COMMAND CMD=get_rotation_distance` を実行
6. Console に `rotation_distance` の設定が表示される

```
# eSun Silk PLA
rotation_distance: 32.14
--
# eSun Silk PLA
rotation_distance: 32.07
--
# eSun Silk PLA
rotation_distance: 8.09
--
enable_pin: !PA4
rotation_distance: 21.77
```

## 各手順の説明（`rotation_distance` の確認）

### G-Code Shell Command Extension のインストール

[G-Code Shell Command Extension](https://github.com/th33xitus/kiauh/blob/master/docs/gcode_shell_command.md) は、Mainsail の Console からシェルコマンドを実行できるようにする KIAUH のプラグインです。

インストール方法は次のとおりです。なお、KIAUH が既にインストールされていることを前提にしています。KIAUH をインストールしていない場合、[th33xitus/kiauh: Klipper Installation And Update Helper](https://github.com/th33xitus/kiauh) を参照してインストールしてください。

1. SSH で Raspberry Pi にアクセスします
2. `kiauh/kiauh.sh` コマンドで KIAUH を起動します
3. Main Menu で `4) [Advanced]` を選択します
4. Advanced Menu で `8) [G-Code Shell Command]` を選択します
5. いくつかの質問に `Y` を回答するとインストールされます

### シェルスクリプトの作成

G-Code Shell Command をインストールしたら、次は `rotation_distance` を確認するためのシェルスクリプトを作成します。

シェルスクリプトの保存場所はどこでもOKなので、以下のコードのスクリプトを `~/get_rotation_distance.sh` で作成しています。スクリプトを作成したら `chmod 777 ~/get_rotation_distance.sh` で実行権限を追加します。

```bash
#!/bin/bash
cat ~/klipper/printer.cfg | grep --before-context=1 ^rotation_distance
```

なお、直前の１行を出力しているのは、私の `printer.cfg` では `rotation_distance` をフィラメント毎に設定しており、設定値の1行前にフィラメント名を記載しているためです。

```
# printer.cfg

# Tinmorry MATT PLA
rotation_distance: 40.153
# Polymaker ABS
#rotation_distance: 40.252
...
```

### printer.cfg の設定

上記のシェルスクリプトを Mainsail の Console から実行できるようにするため、`printer.cfg` に次の設定を追加します。設定は公式ページの設定例を参考にしています。

```
[gcode_shell_command GET_rotation_distance]
  command: sh /home/pi/get_rotation_distance.sh
  timeout: 30.
  verbose: True
```

`printer.cfg` を編集したら次のいずれかの方法で Klipper を再起動します。

1. Mainsail の DASHBOARD の右上の電源ボタンから Klipper の再起動を選択する
2. SSH でアクセスしている Raspberry Pi で `sudo systemctl restart klipper.service` を実行する

こうすると Console で `RUN_SHELL_COMMAND CMD=get_rotation_distance` と入力すると `rotation_distance` の設定値を確認できるようになります。

```
# eSun Silk PLA
rotation_distance: 32.14
--
# eSun Silk PLA
rotation_distance: 32.07
--
# eSun Silk PLA
rotation_distance: 8.09
--
enable_pin: !PA4
rotation_distance: 21.77
```

### rotation_distance の修正

**2022年9月30日加筆修正**

上記の方法で `rotation_distance` の設定値を確認することはできますが、もう一歩進めて設定値の修正までできるようになるとさらに楽になります。

~~そこで `rotation_distance` の設定値を引数として渡すと `printer.cfg` の設定値を変更するシェルスクリプトは作成したのですが、これを Mainsail の CONSOLE から実行する方法が分からないため、この点は現在保留中です。正確に言うと、Mainsail の CONSOLE で複数の引数を渡す方法が分からない（できない？）ため、保留にしています。~~

~~とりあえず KIAUH の Issues で複数パラメーターを渡せる機能を追加して欲しいと[要望](https://github.com/th33xitus/kiauh/issues/233)していますので、機能が実装されるのを待つか、現時点でも可能であればその方法も追記しようと思います。~~

~~なお、シェルスクリプトのコードは次のとおりです。前提として、 `rotation_distance` を設定している行に、コメントで XYZ 軸の区別ができるようにするためのコメントを挿入しています。~~

そのため、まず `rotation_distance` の設定値を引数として渡したら `printer.cfg` の内容を書き換えるシェルスクリプト（`~/ change_rotation_distance.sh`）を作成しました。ある程度のエラーには対応できるように作成していますが、もし不具合がありましたらコメント欄で教えてください。

```bash
#!/usr/bin/bash

Message() {
  cat <<- EOF
This script is change rotation_distance value.
Usage: sh change_rotation_distance -x 40 -y 39.5 -z 8.4
       sh change_rotation_distance -y 40 -z 8
       sh change_rotation_distance -h
 NG -> sh change_rotation_distance -x -y -z 8.9
       sh change_rotation_distance -x -40 -y -40 -z 8.9
EOF
}

isNumeric() {
  if expr "$1" : "[0-9]*$" > /dev/null 2>&1 || ( expr "$1" : "[0-9]*\.[0-9]*$" > /dev/null 2>&1 && [ "$1" != "." ] );then
    return_value=0
  else
    return_value=1
  fi
  return "$return_value"
}

if [ $# -eq 0 ]
then
  Message
  exit 0
fi

while getopts x:y:z:h OPT
do 
  isNumeric "$OPTARG"
  return_value=$?
  if [ "$return_value" -eq 1 ]
  then
    if [ "$OPT" = 'h' ]
    then
      Message
      exit 0
    elif [ "$OPT" != '?' ]
    then
      echo "-${OPT} argument is not a positive number."
      Message
      exit 1
    fi
  fi
  case $OPT in
    x) x_axis="$OPTARG" ;;
    y) y_axis="$OPTARG" ;; 
    z) z_axis="$OPTARG" ;; 
    ?) Message
       exit 1 ;;
  esac
done

if [ "${x_axis}" ]
then
  sed -E "s/^(rotation_distance:)\s?[0-9]+\.?[0-9]+(.+#\s?[xX])/\1 ${x_axis}\2/" -i $HOME/klipper_config/printer.cfg
fi

if [ "${y_axis}" ]
then
  sed -E "s/^(rotation_distance:)\s?[0-9]+\.?[0-9]+(.+#\s?[yY])/\1 ${y_axis}\2/" -i $HOME/klipper_config/printer.cfg
fi

if [ "${z_axis}" ]
then
  sed -E "s/^(rotation_distance:)\s?[0-9]+\.?[0-9]+(.+#\s?[zZ])/\1 ${z_axis}\2/" -i $HOME/klipper_config/printer.cfg
fi
```

あわせて、`printer.cfg` に4つある `rotation_distance` について、どれが XYZ 軸の値なのかを示すコメントを追加して、`sed` コマンドの検索パターンで指定できるようにしました。

```
# printer.cfg

[stepper_x]
rotation_distance: 32.14  # x_axis
[stepper_y]
rotation_distance: 32.07  # y_axis
[stepper_z]
rotation_distance: 8.09  # z_axis
```

~~`sh change_rotation_distance.sh -x 32.14 -y 32.07 -z 8.09` の形で `rotation_distance` の設定を引数として渡します。~~

それから、このシェルスクリプトを Mainsail の Console から実行するためのマクロを作成します。このマクロのコードは、KIAUH の Issues で私が「複数パラメーターを渡せる機能を追加して欲しい」と[要望](https://github.com/th33xitus/kiauh/issues/233)したのに対し、「この方法を試してほしい」と[回答](https://github.com/th33xitus/kiauh/issues/233#issuecomment-1260980803)していただいたものをほぼコピーしています。

```
# printer.cfg

[gcode_shell_command change_rotation_distance]
command: sh /home/pi/change_rotation_distance.sh
timeout: 30.
verbose: True

[gcode_macro change_rotation_distance]
gcode:
    # Set the X, Y, Z variables up here. Assuming that the default is None
    {% set param_data = [] %}

    # If variable is None, ignore and don't add it to param_data list
    {% if X is not none %}
      {% set param_data = param_data +  ['-x ' + X] %}
    {% endif %}
    {% if Y is not none %}
      {% set param_data = param_data +  ['-y ' + Y] %}
    {% endif %}
    {% if Z is not none %}
      {% set param_data = param_data +  ['-z ' + Z] %}
    {% endif %}

    # Join param_data with a space
    {% set param_data = ' '.join(param_data) %}

    RUN_SHELL_COMMAND CMD=change_rotation_distance PARAMS="{pass_data}"
    # Note the quotation marks around the pass_data. Without them, Klipper will attempt (and fail) to interpret each word in the params
```

マクロを作成したら Klipper を再起動して読み込ませます。そして、Mainsail の Console に次のコマンドを入力して実行します。このとき、シェルスクリプトに渡す引数をシングルクォーテーション（`'`）で囲む必要があります。

`RUN_SHELL_COMMAND CMD=change_rotation_distance PARAMS='-x 31.644 -y 31.574 -z 8.042'`

このコマンドを実行すると `Running Command {change_rotation_distance}...:` と表示されてシェルスクリプトが実行され、少し待つと `Command {change_rotation_distance} finished` と実行完了の通知が表示されます。

実際に `rotation_distance` の設定値が変更されたか確認するため、Mainsail の Console に `RUN_SHELL_COMMAND CMD=get_rotation_distance` と入力して実行すると、`rotation_distance` の設定値が変更されていることが確認できます。

{{< bsimage src="image01.png" title="実行結果" >}}
