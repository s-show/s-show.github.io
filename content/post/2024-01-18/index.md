---
# type: docs 
title: Klipper の Timer too close エラーを解消した話
date: 2024-01-18T20:02:41+09:00
featured: false
draft: false
comment: true
toc: true
tags: [3Dプリンタ]
archives: 2024/01
---

## 前置き

我が家の Prusa MK3S+ は公式ファームウェアではなく Klipper 化して印刷していますが、年明けから印刷中に `MCU ‘mcu’ shutdown: Timer too close` エラーが毎回発生して印刷できない状態になってしまいました。

このエラーは以前からまれに発生していたのですが、そのときは Raspberry pi を再起動すれば印刷できていたのに、今回は Raspberry pi を再起動してもエラーが解消されない状態になっていました。

そこでエラー解消のために色々取り組んで、やっとエラーが発生せずに印刷を完了させられるようになりましたので、取り組んできたことなどを備忘録としてまとめます。

## このエラーの内容

このエラーがどういう場合に発生するのかについては、以下のサイトで次のように説明されています。

[Timer too close - Knowledge Base - Klipper](https://klipper.discourse.group/t/timer-too-close/6634)

> This error typically occurs when the host sends a message to the MCU, scheduling an event at a time that is in the past.

> このエラーは、典型的には、ホストがMCUにメッセージを送信し、過去の時刻にイベントをスケジューリングした場合に発生する。（拙訳）

これだけだとよく分からないですが、エラー発生時に補足情報として表示される以下のメッセージと合わせて読むと、Raspberry pi がプリンタのマザーボード（Prusa MK3S+ であれば Einsy board）に命令を送る際に、何らかの原因で送信が滞って現在時刻より前の命令がスケジューリングされてしまった場合に発生するエラーだということが分かります。

```
This often indicates the host computer is overloaded. Check for other processes consuming excessive CPU time, high swap usage, disk errors, overheating, unstable voltage, or similar system problems on the host computer.
```

## 最初に実施した対応策

上記の補足情報で「This often indicates the host computer is overloaded.」とありますので、Raspberry pi の負荷を下げるため、カメラを使わない設定に変更して USBカメラを取り外しました。

そのうえで、同じエラーが発生した時のシステム状況を確認するため、システムタブを録画しながら印刷しましたが、同じエラーが発生したうえ、使用率もエラーが発生する前に跳ね上がるようなことはありませんでした。

ただ、エラーが起きると少しの間だけ画面更新が止まってしまってエラー発生直後の状況が分からなかったため、今度は印刷前に SSH でRaspberry pi にアクセスして、印刷中の負荷を `dmstat` コマンドで確認するという方法を採りました。すると再びエラーになりましたが、エラー発生前に負荷が上昇するということはありませんでした。むしろ、エラーが発生した後に負荷が上昇していました。これは、エラー発生に伴う後始末を行っているためと思われます。

## 解決に至った対応策

カメラを外す以外に Raspberry pi の負荷を下げる方法が思いつかず行き詰まっていましたが、上記で紹介した解説ページで挙げられていた原因の中に「Disk errors / dying SD card」があったのを思いだしたので、Raspberry pi OS をインストールしている USBメモリを確認することにしました。

確認方法ですが、Check Flash というソフトで USBメモリの全セクタについてチェックするという方法を採用しました。

ソフトダウンロード先（ソフト作者のウェブサイトが消滅していますので Internet Archive をリンク先にしています）
https://web.archive.org/web/20220103143823/http://mikelab.kiev.ua/index_en.php?page=PROGRAMS%2Fchkflsh_en

このチェックは USBメモリのデータを全て削除するため、設定ファイルを手元の PC にダウンロードしてからチェックしました。すると、書き込み不可などのエラーが 1,000近くあることが判明しました。そのため、この USBメモリの不具合が `Timer too close` エラーの原因ではないかと仮定しました。

そこで、同様にエラーチェックしてもエラーが出ない USBメモリにシステム一式をインストールして必要な設定も行い、プリンタのマザーボードに新しいファームウェアを書き込みました。そして、エラーが発生していた時に印刷しようとしていたモデルを、同じ設定でスライスして印刷したところ、`Timer too close` エラーが発生することなく印刷が完了しました。

それから他のモデルも印刷していますが、`Timer too close` エラーは発生していないので、`Timer too close` エラーの原因は壊れ始めていた USBメモリだったようです。

この記事が同じエラーに悩まされている方にとって何かの参考になれば幸いです。

### 補足

USBメモリの更新に伴って Klipper のバージョンも新しくなっていますが、`Timer too close` エラーで印刷できなかったときと同じバージョンで昨年末までは印刷できていましたので、Klipper のバージョンアップはエラーの原因とは考えにくいところです。
