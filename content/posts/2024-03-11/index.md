---
# type: docs 
title: Raspberry pi のネットワークの改善
date: 2024-03-11T00:18:30+09:00
featured: false
draft: false
comment: true
toc: true
tags: [3Dプリンタ,RaspberryPi]
---

## 前置き

3Dプリンタの Voron Trident を Raspberry pi4 で制御していますが、OS をインストールしている USBメモリの調子が悪くなってきたので、先日、キオクシアの USBメモリにシステムをインストールしました。

システムインストール後、これまでどおり Raspberry pi4 を Voron Trident の底面に設置したところ、Wifi 接続のネットワークが不調で、SSH はしょっちゅう切れるかそもそも繋がらない、ブラウザで操作画面を開こうとしても開けないという事態になりました。

これでは印刷ができないので、原因を究明することにしました。

## 調査

Raspberry pi4 は Voron Trident の底面に設置していますので、障害物で電波が弱まっているのかと思い、Voron Trident の底面から取り外して有線で接続して調査しました。

まず、Wifi が壊れていないか調べるため、[uoaerg/wavemon: wavemon is an ncurses-based monitoring application for wireless network devices on Linux.](https://github.com/uoaerg/wavemon) をインストールして確認しました。その結果ですが、間に障害物が無ければ link quiality は 100％、signal level は -20dBm 程度と全く問題ありませんでした。つまり、Wifi 機能には問題が無いということになりました。

そこで、先人の知恵を借りるべく調査したところ、Wifi の Power Management が ONになっていると一定時間経過後に Wifi がサスペンドされてしまうので、不安定なネットワーク接続は Power Management を OFF にすれば解決できるという記事が複数見つかりました。

OS 再インストール前から SSH 接続しているときにプチフリーズすることがよくありましたので、この解決策は効果がありそうに見えました。そこで、この解決策を採用してみることにしました。

まずは Wifi の Power Management が ON になっているか調べるため、`iwconfig wlan0 wlan0` コマンドを実行して現在の設定を確認しました。すると、以下のとおり Power Management が ON になっていました。

```
iwconfig wlan0 wlan0
  IEEE 802.11 ESSID:"xxx"
  〜省略〜
  Power Management:on
```


## 対処

Wifi の Power Management を OFF にする方法は、`sudo iwconfig wlan0 power off` コマンドを実行することですが、この方法では Raspberry pi を再起動したときに再び Power Management が ON になってしまいます。Raspberry pi を再起動しても Power Management を OFF にしたままにするためには、`**/etc/rc.local` に `iwconfig wlan0 power off` を追加する必要があります。

```
#!/bin/sh -e
#
# rc.local
（略）

iwconfig wlan0 power off <- 追記箇所

exit 0
```

これで Raspberry pi を再起動しても Wifi の Power Management が OFF になったままになります。

## 結果

この処置を行ったところ、Raspberry pi を Voron Trident の底面に設置した状態でも SSH がきちんと繋がり、また、ブラウザの操作画面も問題なく開けるようになりました。

また、`wavemon` コマンドで電波の強度を確認したところ、さすがに障害物が全く無い状態よりは弱くなっていますが、実用上は問題ない電波強度があることが確認できました。

{{< bsimage src="./wavemon_result.png" title="wavemon の結果" >}}

## 参考情報

この問題の解決にあたって参考にした情報は以下のとおりです。

- [Raspberry Pi4B WiFi調査メモ #RaspberryPi4 - Qiita](https://qiita.com/god19/items/f21d274b45688d9679fa)
- [Raspberry PiのWi-Fi接続が不安定なのをPower Management設定変更で解決した - スズハドットコム](https://suzu-ha.com/entry/2023/12/25/000000)
- [Raspberry Pi Zero WHが定期的にネットワークに繋がらなくなるので対策 | A Journey of English Study](https://english-journey.com/raspberry-pi-wifi-power-management/)
- [無線状況が良好なRSSI（電波強度）はどの程度ですか | バッファロー](https://www.buffalo.jp/support/faq/detail/1838.html)