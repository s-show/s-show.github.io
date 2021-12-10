---
title: 'Karabiner-Elementsを使ってMacのキーボード操作を快適にする方法'
date: Sat, 25 Nov 2017 12:35:30 +0000
draft: false
tags: ['Karabiner-Elements', 'Mac', 'プログラミング']
---

Karabiner-Elementsとは
====================

Karabiner-Elementsは、Macのキーボードカスタマイズアプリで、設定ファイルを自分で記述することで以下のような機能を実現できます。

*   "control-H"のようなキー入力を"Command-A"の入力に変換
*   "Escape"を１回入力したら"Escape, 英数, Escape"のようなキー入力を実現する
*   "control-2"のようなキー入力に`"open -a 'safari'"`のようなシェルコマンドの実行を割り当てる
*   "スペースバー"を押している間だけ、"H, J, K, L"をカーソルキーに変換する
*   "control-x control-c"のようなキー入力を"command-Q"の入力に変換したり、シェルコマンドの実行を割り当てる。
*   左右のコマンドキーを押すとIMEをオン・オフできるようにする

同じキーボードカスタマイズアプリで、同じ開発者が開発していたKarabinerがmacOS Sierraで使用できなくなったため、後継アプリとして開発されています。ちなみに、KarabinerはKeyRemap4MacBookと呼ばれていたアプリです。 アプリの配布場所：[Karabiner-Elements](https://karabiner-elements.pqrs.org/)

Karabiner-Elementsを使って実現した機能（主なもの）
==================================

Karabiner-Elementsを使うと様々な機能を実現することが可能で、コピーなどの各種操作をWindowsと同じにしたり、キーボードの配列をQWERTYからDVORAKに変更するカスタマイズまでしている人もいるようです。そこまでいかなくても、以下のページを見ると、たくさんのユーザーが実に様々な設定を行なっていることが分かります。 [Karabiner-Elements complex\_modifications rules](https://pqrs.org/osx/karabiner/complex_modifications/) 私が行っている設定のうち、主なものは以下のとおりです。

*   IMEの切り替え方法の改善
    *   全角/半角キーでIMEを切り替え
    *   変換/かなキーでIMEオン
    *   無変換キーでIMEオフ
*   ブラウザ（Safari, Chrome, Firefox）やターミナルのタブの移動をctrl-pageup(down)で行えるように設定
*   Windowsと同様の動作を実現
    *   F5キーでブラウザの更新を行う
    *   Shift-F10やアプリケーションキーに右クリックを割り当て
    *   PrintScreenで画面全体のスクリーンショット撮影
    *   Option-PrintScreenで指定したウィンドウのスクリーンショットを撮影
    *   Finderでファイル(フォルダ)を選択してDeleteを押すとファイルをゴミ箱へ移動
    *   Command-EでFinderを開く
    *   Control-EscapeでLaunchPad表示（スタートメニュー表示の代わり）
*   Windowsのキーボードユーティリティーソフトのenthumbleと同様の操作を実現
    *   無変換/英数 + I, J, K, L -> 矢印キー（←, ↓, ↑, →）
    *   無変換/英数 + A, S, W, D -> 矢印キー（←, ↓, ↑, →）
    *   無変換/英数 + B, N, P, F -> 矢印キー（←, ↓, ↑, →）
    *   無変換/英数 + H, J, K, L -> 矢印キー（←, ↓, ↑, →）※この組み合わせを使用中
    *   無変換/英数 + Space/かな -> Enter/Escape
    *   無変換/英数 + N, M -> BackSpace
    *   無変換/英数 + ',' '.' -> Delete
    *   無変換/英数 + Y, U -> BackSpace
    *   無変換/英数 + I, O -> Delete
    *   無変換/英数 + 矢印キー（←, ↓, ↑, →）で「←, ↓, ↑, →」を入力
*   Windowsのキーボードユーティリティーソフトの秀Capsの「テンキーのピリオド２連打でコンマ入力」を実現

上記の他にも設定している項目はあります。設定ファイルは、GitHubで管理していますので、適宜開いて見てください。また、Karabiner-Elementsには、設定ファイルを自分で書かなくても、他の人の設定をインポートして使用可能にする機能があります。上記の設定を紹介しているページからも設定をインポートできますし、私の設定であれば、以下のリンクからインポートできます。 設定ファイル（JSONファイル）：[KE-complex\_modifications](https://github.com/s-show/KE-complex_modifications/) Karabiner-Elementsに読み込ませる設定ファイルは、`docs/json/`ディレクトリにあります。 設定のインポートページ：[Karabiner-Elements complex\_modifications rules by s-show](https://s-show.github.io/KE-complex_modifications/)

設定で工夫した点
========

Emacsの２ストロークキーや、一つのキーを押している間だけキーの変換を行いたい場合、Karabiner-Elementsには専用の設定がありません。そのため、キーを押しているか否かをアプリで判断するため、変数を使ってフラグを立てて判断したり、トリガーとなるキーを"fn"キーに一時的に変換し、"fn"と合わせて押した場合のみ変換を行う、などのテクニックが必要となります。

Emacsの２ストロークキーの設定は、最初は非常に面倒な作業でした。割り当てたいキーを指定するだけなら簡単でしたが、キー入力を間違えた時に備えたエラー処理を全てのキーについて行う必要があり、設定を記述したJSONファイルが17,000行以上になったこともありました。その後、Karabiner-Elementsに新しい機能が追加され、その機能を利用したら設定ファイルが220行程度まで縮小できました。また、一つのキーを押している間だけキーの変換を行うという設定については、当初は変数を使ってフラグを立てる方法で実装していましたが、GitHubにある設定例を見て、トリガーとなるキーを一時的に`"fn"`キーに変換し、`"fn"`と合わせて押した場合のみキーの変換を行うという設定方法を知ってから、変数をチェックする処理や変数の初期化処理が不要となり、設定がシンプルに行えるようになりました。さらに、先日、開発者がリファレンスを作成してくれましたが、このリファレンスに掲載されていた例を参考にすることで、「テンキーのピリオド２連打でコンマ入力」を実現する方法が思いついたりもしました。

あと、Karabiner-Elementsはキー変換とコマンド実行の機能しかないため、enthumbleの「"無変換/英数 ＋ カーソルキー" で "←↑↓→"を入力」という機能を実現するのには試行錯誤しました。最初は、`"shell_command": "echo '←' | pbcopy | pbpaste"`で上手くいくかと思いましたが、よく考えると、`pbcopy`も`pbpaste`も標準入出力が対象になっているので、それ以外の場面で動くことはないことに気付きました。

次に、"←"を一旦クリップボードにコピーして、それをペーストすれば文字入力と同じ結果が得られると考えて、以下の方法を試しました。しかし、クリップボードに"←"をコピーするところまではできましたが、クリップボードへのコピーより先に"command-v"が実行されてしまいました。

```
{ "shell_command": "osascript -e 'set the clipboard to \"←\"'" },
{
  "key_code": "v",
  "modifiers": ["option"]
} 
```

どうも、AppleScriptの動作が遅いことが原因で、`"osascript -e 'set the clipboard to \"←\"'"`の処理が終わる前に"command-V"の処理が行われたようでした。`"osascript ~~~"`の処理が終わるまで"command-V"を実行しないという処理を実現する方法は全く分かりませんでしたので、"←"のクリップボードへのコピーもペーストもAppleScriptで行うように設定したところ、動作は遅いものの、狙い通りの機能が実装できました。

```
{ "shell_command": "osascript -e 'set the clipboard to \"←\"'" },
{ "shell_command": "osascript -e 'tell application \"System Events\" to keystroke \"v\" using command down'" } 
```

カスタマイズの効果
=========

自分が欲しい機能を順次実装しているので、Macの操作は随分と楽になっています。特に、Windowsでは可能なのにMacでは不可能な操作（全角/半角キーでのIME切り替えなど）が可能になり、２つのOSを使う際に戸惑うことが少なくなりました。

今ではむしろ、"ctrl-h/d → Backspace/Delete"のように、Macでは可能だがWindowsではカスタマイズしないと実現できないキー操作を実現する方法が欲しくなっています。

また、「全角/半角キーでIMEを切り替え」や「Controlキー連打で特定の処理実行」といったカスタマイズは、Macのシステム環境での設定とKarabiner-Elementsを組み合わせたり、BetterTouchToolを使って実現したりしていましたが、そうした設定を全てKarabiner-Elementsだけで可能となり、設定の管理も非常に楽になりました。

本記事の補足情報
========

QiitaでKarabiner-Elementsの設定項目の解説や設定例を掲載していますので、よろしければそちらも見てください。

- [Karabiner-Elementsの各設定項目の内容について](https://qiita.com/s-show/items/a1fd228b04801477729c)
- [Karabiner-Elementの設定例について - Qiita](https://qiita.com/s-show/items/40ad22c4ee4a0465fad5)
- [Karabiner-Elementsを使ってJISキーボードの"全角/半角"でIMEを切り替える方法 - Qiita](https://qiita.com/s-show/items/08a7c1b558e4d7e6f1b0)
- [Karabiner-Elementsの設定項目が増えてEmacsライクな設定が楽になった - Qiita](https://qiita.com/s-show/items/e83215f4ee10422abd7c)
- [Karabiner-Elementsでenthumble(Windows App)のような操作を実現する方法 - Qiita](https://qiita.com/s-show/items/0036e45d4b5928569dd9)
- [Karabiner-Elementsを使ってキーの２連打に処理を割り当てる方法 - Qiita](https://qiita.com/s-show/items/c991327a5317c3e0cf4b)
- [KE-complex\_modificationsを使ってKarabiner-Elementsの設定を楽にする方法 - Qiita](https://qiita.com/s-show/items/fb788d90faba7eeb9051)