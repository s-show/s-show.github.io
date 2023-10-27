---
# type: docs 
title: 2022 10 01
date: 2022-10-01T01:27:49+09:00
featured: false
draft: true
comment: true
toc: true
reward: true
pinned: false
carousel: false
series:
categories: []
tags: []
images: []
---


getopts 備忘録

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


## 引数の数を確認する

`$#` 変数に引数の数が格納されているので、`if [ $# -eq 0 ]` とすれば引数がゼロ個の場合の処理に分岐できる。


## 名前付き引数の引数名と引数の取り出し方

以下のコードでは `getopts` コマンドのオプション文字列に `x:y:z:h` と指定することで、このシェルスクリプトの引数として `-x -y -z -h` という名前付き引数を使えるようにしている。

```bash
while getopts x:y:z:h OPT
do 
  if [ "$OPT" = 'h' ]
  then
    echo 'hogehoge'
    exit 0
  fi
  case $OPT in
    x) x_axis="$OPTARG" ;;
    y) y_axis="$OPTARG" ;; 
    z) z_axis="$OPTARG" ;; 
    ?) Message
       exit 1 ;;
  esac
done
```

名前付き引数のうち、 `-x -y -z` は値を必須とする引数としているため、`-x 40 -y 39 -z 8` のような形で値が渡されることになる。渡された値は `$OPTARG` 変数に格納されているので、上のコードでは `x_axis="$OPTARG"` として値を取り出している。


## 名前付き引数の一部しか渡されなかった場合の挙動

## 指定していない名前付き引数が渡された時の挙動

## 値を必要とする名前付き引数と値を必要としない名前付き引数を同時に指定する方法

値を必須とする名前付き引数を指定するときは、引数の後ろに `:` を追加すればよいので、`getopts x:y:z:h` とすれば、`xyz` は値を必須とする引数に、`h` は値を必須としない引数として同時に指定することができる。

## 引数が数値か否か確認する方法


