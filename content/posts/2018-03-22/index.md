---
title: 'Macbook proでメモリ交換して電源が入らなくなってから復活するまでの経緯'
date: Tue, 22 May 2018 14:34:04 +0000
draft: false
tags: ['Mac', '備忘録']
---

前置き
---

メルカリで売りに出ていた「Macbook pro, 2011Early, 15インチ」を購入して、さらにメモリを16GBに増強して快適な環境を構築しようとしたら、メモリ交換後に電源ボタンを押しても反応がないというまさかの事態に陥ってしまった。何とか蘇らせることができてこの記事を書けるまでになったので、同じ症状に遭遇した人のために、顛末を書いてみたいと思う。

経緯（購入まで）
--------

それまで使用していたMacbook pro(2015, 13インチ)は、持ち歩きも考慮して13インチにしたものの、据え置きで使うことが多く、また、据え置きで使うべく外付けディスプレイやキーボードを接続しているので、外に持ち出す都度、ケーブル類や電源の着脱が手間になっていた。

そこで、もし、安価な15インチのMacbook proがあればそれを据え置き機にして、既存の13インチは持ち歩き専用にしようと思い立ち、メルカリで探したらちょうど良い商品があったので、Amazonで16GBのメモリを購入するのと合わせて、早速購入した。

経緯（商品到着からメモリ交換実施まで）
-------------------

メルカリで購入したMacとAmazonで購入したメモリが同時に届いたので、まずはMacの起動確認を行い、ちゃんと起動することを確認したら、出品者を評価してからMacの電源を落とした（後述するが、多分この時に、間違えて電源オフではなくスリープにした可能性がある。） それから、以下のページを参考にしてメモリを交換して、上手くいったか確認するために電源ボタンを押した。 [MacBook Pro：メモリの取り外し方法と取り付け方法 - Apple サポート](https://support.apple.com/ja-jp/HT201165)

・・・全く反応がない。。。

一体何が起きたか分からなかったが、交換したメモリに不具合があるかと思い、元から取り付けられていたメモリに戻して電源ボタンを押す。

・・・さっきと同じように全く反応がない。。。

ここまで来て事態の深刻さに気付き、対処策を探すことになる。

経緯（試行錯誤の過程）
-----------

まずはネットで同様の症状に遭遇した人がいないか検討するが、電源が入らなくなった時の対処方法は見つかるものの、メモリ交換で電源が入らなくなった事例は見つからなかった。

仕方なく、[NVRAMのリセット](https://support.apple.com/ja-jp/HT204063)や[SMCのリセット](https://support.apple.com/ja-jp/HT201295)を試すものの、全く事態は改善されない。

最初のトラブルの時にNVRAMリセットを行っても復旧しなかったが、３時間後にリセットしたら復旧したという記事も見つけたので、２時間ほど経ってからリセットしてみるが、反応が無い状態は全く変わらない。

対象方法を探す中で地元の修理ショップの存在を発見するが、ロジックボードの修理費が３〜６万円とあるのを見て、これだけ出すなら諦めた方が安上がりかなという考えも浮かんでくる。

また、この辺りになると、最初の起動確認をした後、いつもの癖で電源オフではなくスリープを選んでしまい、その状態でメモリ交換をしてしまったのではないかという嫌な予感がして来てしまい、さらに気が滅入ることになる。

とはいえ、あれこれ作業をしていると夜遅くになってしまったので、仕方なくその日はそれ以上の作業を諦めて寝ることにした。

経緯（復旧まで）
--------

次の日は朝から用事があったため、夕方に帰って来てから作業に取り掛かった。

昨日、スリープ状態でメモリ交換をしてしまった可能性を考えていたので、一度完全に電源オフにした上で、あらためてNVRAMリセットとかしたら復旧するのはないかと思い、バッテリーを取り外すことにした。 以下のページを見ながらバッテリーを取り外し、その状態で一度電源ボタンを押して内部の電気を完全に放出したうえで、２時間ほど待つことにした。 [MacBook Pro 15" Unibody Early 2011 Battery Replacement](https://jp.ifixit.com/Guide/MacBook+Pro+15-Inch+Unibody+Early+2011+Battery+Replacement/5889)

２時間待ったところで、バッテリーを取り付けて電源ボタンを押したところ、DVDドライブへのアクセス音が聞こえてMacの起動音が鳴り、少ししてからMacが無事に起動した。この時は本当にホッとしたのを覚えている。

Macが無事に起動するのを確認したが、内部時計がおかしくなっていたのと、一度リセットした方が良いと判断して、あらためて電源オフにしてから、NVRAMリセットを行ったところ、内部時計もちゃんとした日時になった。動作にも問題がないので、

1.  SMCリセット
2.  OSをOS X LionからHigh Sierraにアップグレード
3.  外付けHDDにバックアップしたTimeMachineのデータを使用して環境を移行

の作業を行い、こうしてブログ記事を書けるまでの環境構築に成功した。

まとめ
---

トラブルの原因は、起動確認後に間違えて電源オフではなくスリープを選んでしまっていて、それに気づかないままメモリ交換に着手してしまったことではないかと思う。OSのアップデートでもない限り、電源オフではなくスリープを選んでいるので、その癖でスリープを選んでいたのではないかと思う。

電源ボタンを押しても反応が無い時はNVRAMのリセットもできないので、こういう時はダメ元でバッテリーを外して完全に電源オフにし、その状態をしばらく続けた後にリセットすると直るかもしれない。 この記事が誰かの役に立てば幸いである。

蛇足
--

元々使っていたMacbook proの環境を移行するため、外付けHDDにTimeMachineでデータをバックアップして移行したが、アプリやデータに加えて各アプリの設定まで自動的に移行されるのには驚いた。新しいMacで行う必要があった作業は、Homebrewを使うためにXcodeをインストールすることだけで、Karabiner-Elementsの設定も1Passwordの設定もそのまま移行されたので、環境移行は拍子抜けするほど簡単だった。

ただ、買った直後のOSがOS X Lionだったが、このOSには２ファクタ認証の機能がないので、iCloudの設定などでIDとパスワードを入力しても、確認コードを入力する画面が表示されず随分と困った。

この問題には、パスワードの後に確認コード６桁を入力すれば対処できる。具体的には、まず、IDとパスワードを一度入力し、手持ちのiPhoneなどに確認コードが表示されたら、再度IDとパスワードを入力し、そのパスワードの後ろに確認コード６桁を入力すれば認証される。 [Mac OSでApple IDの確認コード画面が表示されない場合の対応方法 | 好きな音楽をいい音で](https://music.iiotode.com/?p=9151)