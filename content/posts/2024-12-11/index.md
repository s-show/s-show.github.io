---
# type: docs 
title: 久しぶりにキーボードを設計した話
date: 2024-12-11T20:20:57+09:00
featured: false
draft: false
comment: true
toc: true
tags: [自作キーボード]
---

## 前置き

この記事は、[キーボード #1 Advent Calendar 2024](https://adventar.org/calendars/10116)11日目の記事です。前日の記事は、ゆびながモンキーさんの[気楽にキーボード設計して天キー持っていこうぜって話｡](https://zenn.dev/yubinagasaru/articles/29b1c9f94d862c) でした。天キーのキーボードのレベルが高いというのは私も実感するところでして、2023年3月の天キーに参加したときもハイレベルなキーボードが多数展示されていて、自分のキーボードを展示するのが少々気後れしました。

さて、私がキーボードの記事でアドベントカレンダー向けに執筆するのは2020年以来です。キーボードから離れていた訳ではありませんが、記事のネタが無かったので参加できていませんでした。

今回は、2020年のアドベントカレンダーの記事で「設計中です」としていたキーボードについて、やっと自分なりに満足できる形になってきましたので、このキーボードの設計の意図なんかを書いていきます。

## 設計したキーボード

この[リポジトリ](https://github.com/s-show/yamanami_keyboard)にある「Yamanami Keyboard」の Cherry MX 版のキーボードです。

{{< bsimage src="img/yamanami_keyboard.jpg" title="Yamanami Keyboard Cherry MX" >}}

自作キーボードでしばしば見かける OLED を搭載した上で、QMK Firmware の機能として用意されているものの実例はほとんど見かけない DIP スイッチを搭載したキーボードです。また、これらの部品を使えるだけのピン数を賄うため、RP2040 搭載ボードで GPIO ピンが20ピンある [WaveShare RP2040](https://www.waveshare.com/wiki/RP2040-Zero) を使っています。

### キーボードに求めた機能

このキーボードは、以下の要求を見たすために設計しました。

1. 配列はColumn Staggerd
2. 形状は左右分離型
3. キー数は48
4. 親指で『Space/BackSpace、Lower/Raise、Win/CMD、Alt』キーが押せる
5. プレートとケースは3Dプリントで作る
6. `qmk flash` コマンドを実行しなくてもファームウェアを更新できる
7. OS のキーボード配列を US(JIS) から JIS(US) に変更しても DIP スイッチ1つで対応できる
8. キーキャップを US(JIS) から JIS(US) に変更しても DIP スイッチ1つで対応できる
9. 現在のレイヤー設定がターゲットとしている OS のキーボード配列とキーキャップ配列を OLED に表示する
10. 右手側の OLED にロゴを表示する
11. 可能な限り `keyboard.json` に設定を書く
12. PCBA に挑戦する

### 各機能を求めた理由

各機能を求めた理由は以下のとおりです。

- 配列を Column Staggerd にした理由は、これまで Row Starggerd、Ortho Linear と使ってきた経験から、私の手に一番合うと思える物理配列が Column Staggerd だからです。
- 私は手が大きくないため、ホームポジションから手を動かさなくても良いキー数は48キーが限界です。
- 両腕を適度に広げるため形状を左右分離型にしました。左右分離型に慣れると一体型キーボードは窮屈に感じてしまいます。
- 親指で『Space/BackSpace、Lower/Raise』が押せることについては、こういうキー操作を実現するためにキーボードを設計しているので、当然必要な機能です。
- プレートとケースを3Dプリンタで作成することについては、自宅で試行錯誤できて金属切削より安く済みますので、自作の醍醐味として盛り込んでいます。
- PicoMicro の「`.uf2` ファイルをコピペすればファームウェアを更新できる」という簡単な方法に慣れたため、引き続き同様の取り扱いができるようにしました。
- 7 の機能は、テレワークで職場のPC（OS のキーボード配列は JIS で固定）を使う場合に備えて盛り込んだ機能です。8 は 7 に関連して盛り込んだ機能で、7 を実現するなら 8 も実現したいということで盛り込みました。
- 9 は 7 と 8 に関連した機能で、DIP スイッチを切り替えたら OLED の表示を変更することで、現在のキーマップがどの環境をターゲットにしているか手元で確認するために盛り込みました。
- 10 は PCB 基板の裏面に印刷したロゴを手元側でも見たいということで盛り込みました。
- 11 は QMK Firmware が推奨している [Data Driven Configuration](https://docs.qmk.fm/data_driven_config) に合わせるべく導入しました。なお、QMK の公式リファレンスでは `info.json` となっていますが、`keyboard.json` でも問題ありません。
- 12 は 自分の手間を減らすことと、Self-Maid Keyboards in Japan の方々が結構頼んでいるみたいなので、自分もやってみることにしました。作業を頼んでもそこまで高くならないのは助かりました。

なお、以前はマイコン直付け方式で設計したいと考えていましたが、マイコン直付けだと故障時の復旧が至難の技になるため、マイコンはマイコンボードを使う方法にしました。

{{% alert info %}}
3Dプリンタで、マザーボードに直付けされたモータードライバーの1つが数ヶ月で壊れてしまい、修理できなくてボードごと買い替えるという事態に2回襲われたため、マイコンは直付けより外付けの方が良いと思うようになりました。
{{% /alert %}}

### 各機能の実装方法

これらの機能のうち、1-5は今回作ったキーボードの試作品（Yamanami Keyboard choc）で実現していました。

6は RP2040 マイコンを使ったマイコンボードのファームウェア更新方法なので、RP2040 を使えば自動的に実現可能です。RP2040 を使う場合、`keyboard.json` に以下の設定を追加します。

```json
    "bootloader": "rp2040",
    "processor": "RP2040",
```

7 については、[OS のキーボード配列が JIS キーボードの時の QMK Firmware の設定について](https://kankodori-blog.com/posts/2022-08-07/) で紹介した QMK Firmware の Key Override 機能と、[QMK Firmware で DIP スイッチを使う方法](https://kankodori-blog.com/posts/2024-10-13/) で紹介した DIP スイッチを使う方法を組み合わせて実現しました。

具体的な実装方法は、まず、Key Override 機能を使って OS のキーボード配列が US の場合のキーマップと JIS の場合のキーマップを作成します。そして、DIP スイッチを使うための下準備をしてから `keymap.c` に `dip_switch_update_mask_user()` 関数を追加して `switch` 文で DIP スイッチの状態に合わせて `set_single_persistent_default_layer()` でデフォルトレイヤーを US 向け or JIS 向けの間で切り替えます。また、US 向けのキーマップでは Key Override 機能は使わないため、`key_override_off()` 関数を実行して Key Override を無効化します。JIS 向けのキーマップを使う場合、デフォルトレイヤーを切り替えるとともに、`key_override_on()` 関数を実行して無効化していた Key OVerride を再度有効化します。

8 については、キーキャップを見ながら調整しないと頭が混乱しそうなので、 JIS キーキャップを入手するか3Dプリンタで一部の JIS キーキャップを印刷してからキーマップを作成する予定です。キーマップができたら、上の7と同様に実装していきます。

9 と 10 については、QMK Firmware の OLED 機能を活用して対応しています。ロゴの作成に少し手間どりましたが、何とか満足できるロゴができました。ロゴを表示させる方法は [QMK Firmware でオリジナルロゴを表示する方法](https://kankodori-blog.com/posts/2024-11-05/) のとおりです。

また、デフォルトレイヤーの切り替えに伴う表示の切り替えでは、[QMK Firmware で DIP スイッチを使う方法](https://kankodori-blog.com/posts/2024-10-13/#%E3%83%87%E3%83%95%E3%82%A9%E3%83%AB%E3%83%88%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E3%82%92%E5%88%87%E3%82%8A%E6%9B%BF%E3%81%88%E3%82%8B%E6%96%B9%E6%B3%95) で紹介した機能も一部用いています。


## 失敗談や工夫した点など

失敗については、まず、久しぶりに設計したため、左右通信のピンや OLED のピンは左右で同じにしなければならないことを忘れていました。また、`SPLIT_HAND_PIN` で左右判定するためにチップ抵抗を取り付ける設計にしたのですが、JLCPCB から「フットプリントが違うから PCBA できない」と断われてしまいました。1.6x0.8mmのフットプリントを選んだつもりが 0.6x0.3mmのフットプリントを選んでいて、その大きさで抵抗値が合うチップ抵抗がなかったため、抵抗のPCBAは諦めました。この間違いの原因は、インチ表記とmm表記の見間違いです。

幸い、いずれの問題も追加で半田付けで解決できましたので、基板裏面の半田付けは少々汚ないですが問題なく使えています。

{{< bsimage src="img/soldered.jpeg" title="半田付けで解決したところ" >}}

ただ、左右判定は問題ないのですが、右手側に USB ケーブルを差すと DIP スイッチが反応しなくなります。自力では解決策が見つからなかったため、QMK Firmware の GitHub の [Issues](https://github.com/qmk/qmk_firmware/issues/24557) で尋ねたところ、これは現在の仕様ということで、右手側に USB ケーブルを差した状態で左手側の DIP スイッチを使いたければ DIP スイッチをキーマトリックスに組み込む必要があるとのことでした。これは基板設計から変える必要があるので、まずブレットボードでテストしてから設計を変えようと思っています。

一方、PCBA は始めての挑戦でしたが、ウェブにある先人の知恵を拝借することであっさりできました（前述のチップ抵抗除く）。ダイオードの半田付けをしなくても済むのは非常に楽でした。

また、基板外形の設計には [KiCad](https://www.kicad.org/) の PCB Layout ではなく建築用CADの [Jw_cad](https://www.jwcad.net/) を使いました。Jw_cad だと「長さと角度を指定して線を引く」、「スイッチ取り付け穴の線から10mmオフセットした場所に線を引く」といった作業が簡単に行なえますし、図面を `.dxf` ファイル形式でも保存できます。そのため、Jw_cad で基板の外形線を書いて KiCad にインポートしました。

{{< bsimage src="img/jw_cad.png" title="Jw_cad での設計" >}}

その上で、ケースやプレートなどの設計では、KiCad からエクスポートした 3D モデルを Fusion360 にインポートして仮想的な現物合わせをしながら設計しました。そのおかげか、USB ケーブルや TRRS ケーブルの差し込み口は 3Dプリンタで印刷してからサイズを調整する必要がありましたが、その他の部分は微調整で済みました。

キーボードのマウント方式については、最初は以下のようにスイッチプレートから支柱までネジで固定して一体化したものをケースに載せる形を考えていました。これは、住宅の床の組み方をヒントにしたもので、打鍵時の衝撃を支柱を経由してケースに逃がす想定で設計しました。スイッチプレートを2.6mm厚に、スイッチプレートと PCB の間の隙間を3mm厚のプレートにすることである程度重くして、打鍵時の衝撃をまずは PCB と一体化したプレートで受け止めつつ、支柱を経由してケースに衝撃を逃がすという設計です。

{{< bsimage src="img/mount_pattern.png" title="Jw_cad での設計" >}}

これは思ったより良い感じでしたが、せっかく 3D プリンタがあって試行錯誤できるので、さらに変わったマウント方式を試すべく PCB の外周に当たる場所に窪みを付けてOリングを埋め込んで打鍵時の衝撃を吸収するという方法を試してみました。

{{< bsimage src="img/mount_pattern2.jpeg" title="Jw_cad での設計" >}}

この方法は思ったより良い感じで、柔らかいΟリングの上に、ある程度の重量を確保しているプレート&PCBが乗っかることで、打鍵時の衝撃が上手く分散されている感じです。また、場所による打鍵感の違いも感じられません。まあ、数万円の高級キーボードには勝てるとは思っていないですが、自分なりの工夫で良い感じにできたことには満足しています。

## まとめ

久しぶりの設計で色々失敗しましたが、今回は自分なりに結構上手くいったと思っていますし、やっぱりキーボードを設計していくこと自体が楽しいので、引き続きオリジナルキーボードを設計していきたいと思います。

現時点で考えているキーボードは、カラーLCDを使ったマクロパッドです。アプリ毎にレイヤーを用意してショートカットキーを登録し、DIP スイッチでレイヤーを切り替えたら LCD に該当するアプリのロゴを表示する、というキーボードを考えています。カラーLCDの使い方は [QMK Firmware でカラー LCD に画像を表示する方法](https://kankodori-blog.com/posts/2024-10-14/) で解説していますので、よろしければご覧ください。

本記事は、Yamanami Keyboard の Cherry MX 版で書きました。