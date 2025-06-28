---
title: ZSH を使いながら Windows Terminal でコマンドを実行した行にジャンプする方法
date: 2025-06-28T23:06:00+09:00 # Date of post creation.
featured: false
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: true
usePageBundles: false # Set to true to group assets like images in the same folder as this post.
featureImage: '' # Sets featured image on blog post.
featureImageAlt: '' # Alternative text for featured image.
figurePositionShow: true # Override global value for showing the figure label.
tags: [ZSH, Windows Terminal]
archives: 2025/06
comment: true # Disable comment if false.
---

## 前置き

ターミナルアプリは、現在は消去法で Windows Terminal を使っていますが、他のアプリも色々試していて、その中でも Warp Terminal の「コマンドと実行結果を1つのブロックにまとめる」ブロックエディタにかなり興味を惹かれました。

といいますのも、100行を軽く越える大量の出力があった場合（`sudo nixos-rebuild switch --flake . --impure --show-trace` のエラー発生時など）、どこからどこまでが1つのコマンドの結果なのかを確認するだけでも面倒なので、同様の機能を実現できないか調べてみました。

その結果、ターミナル画面に残っているコマンド入力箇所に画面をスクロールする機能や、コマンドと結果を右クリックから選択できる機能を実現できましたので、実装方法などを備忘録としてメモします。

なお、文字で読むだけでは実際の動作が想像しにくいかと思いますので、こちらに実際の動作の様子も掲載します。

<video class="video-shortcode" preload="auto" controls>
  <source src="https://github.com/s-show/s-show.github.io/raw/refs/heads/master/content/posts/2024-10-14/image/change_image.MP4">
</video>

## 実装の概要

以下の機能を組み合わせて希望する動作を実現します。

- エスケープシーケンスの `OSC 133`
- Windows Terminal の「スクロールバーにマークを表示する」機能
- Windows Terminal の「scrollToMark」コマンド
- Windows Terminal の「右クリックでメニューを表示する」機能

この4つの機能の組み合わせですが、まず、ZSH のビルトイン関数を使ってプロンプト（以下の図の赤枠部分）の前後にエスケープシーケンスを追加します。

{{< bsimage src="./images/prompt.png" title="プロンプトの範囲" >}}


追加するエスケープシーケンスは `OSC 133` で、これはプロンプトの始まりや、コマンドの始まり・終わりを示すもので、今回は以下の3つを使います。

<dl>
  <dt><code>OSC 133 ; A ST</code></dt>
  <dd>プロンプトの開始地点</dd>
</dl>
<dl>
  <dt><code>OSC 133 ; B ST</code></dt>
  <dd>コマンドの開始地点 (プロンプトの終了地点)</dd>
</dl>
<dl>
  <dt><code>OSC 133 ; D ; <ExitCode> ST</code></dt>
  <dd>コマンドの終了地点</dd>
</dl>

プロンプトの前後にこれらのエスケープシーケンスを追加すると、Windows Terminal がプロンプトの位置をマーキングしてくれます。

そして、Windows Terminal の `scrollToMark` コマンドはマーキングした場所まで画面をスクロールしますので、ターミナルの履歴に複数残っているプロンプトの位置に画面をスクロールすることができます。

また、「右クリックでメニューを表示する」をオンにすると、ターミナル上で右クリックした際にコンテキストメニューが表示され、その中にある「コマンドの選択」をクリックすると、コマンドと結果を選択できます。

## 具体的な実装

ここからは具体的な実装を説明します。

### ZSH の設定

まず、`~/.zshrc` に以下の設定を追加します。

```
precmd() {
  print -P "\e]133;D;\a"
}
PROMPT=$'%{\e]133;A\a%}'$PROMPT$'%{\e]133;B\a%}'
```

`precmd()` は、プロンプト文字列出力の直前に実行する処理を設定するための関数です。

ここで使っている `print` コマンドは、`echo` と同様に与えられた引数を標準出力に書き出すもので、オプションの `-P` はプロンプト文字列展開を行うためのオプションです。なんか難しそうに聞こえますが、`\e]133;D;` はエスケープシーケンスの `OSC "133;D;"` を表わす文字で、その後の `\a` は[ベル文字](https://ja.wikipedia.org/wiki/%E3%83%99%E3%83%AB%E6%96%87%E5%AD%97)です。つまり、プロンプト文字列出力の直前（プロンプト文字列一行上）にコマンド終了を表わすエスケープシーケンスを出力しているということです。

次の `PROMPT=$'%{\e]133;A\a%}'$PROMPT$'%{\e]133;B\a%}'` は、プロンプトに表示する文字列を設定しているシェル変数の `PROMPT` をカスタマイズしているものです。

`PROMPT` に代入している値を分解しますと、まず、`$'...'` は `\` をエスケープシーケンスとして解釈するための指示です。ここでは `\e` で ESC 文字を表わすために指定しています。

次の `%{...%}` は、エスケープシーケンスを括るもので、これで括らないとプロンプトの文字数計算がずれてしまいます。

その次の `\e]133;A` は、エスケープシーケンスの `OSC "133;A"` を表わす文字列で、その後の `\a` は前述のベル文字です。

その後に `$PROMPTS` を追加して、元々の `PROMPT` シェル変数を再利用しています。

その次の `\e]133;B` は、エスケープシーケンスの `OSC "133;B"` を表わす文字列で、その後の `\a` は前述のベル文字です。

これにより、元々のプロンプト文字列をエスケープシーケンスで囲むことができました。

ZSH の設定は以上ですので、`source ~/.zshrc` を実行して設定を読み込みます。

### Windows Terminal の設定

次に Windows Terminal を設定します。設定画面だけでは設定できないため、`.json` ファイルを編集する必要があります。

まず、設定タブを開いて「プロファイル→既定値→詳細設定」と進み、「スクロールバーにマークを表示する」と「右クリックでメニューを表示する」を有効にします。

それから「JSONファイルを開く」をクリックして `settings.json` を開き、既存のコードに以下のコードを追加します。

```json
"actions":
[
    // Scroll between prompts
    { "keys": "ctrl+up",   "command": { "action": "scrollToMark", "direction": "previous" }, },
    { "keys": "ctrl+down", "command": { "action": "scrollToMark", "direction": "next" }, },

    // Add the ability to select a whole command (or its output)
    { "command": { "action": "selectOutput", "direction": "prev" }, },
    { "command": { "action": "selectOutput", "direction": "next" }, },

    { "command": { "action": "selectCommand", "direction": "prev" }, },
    { "command": { "action": "selectCommand", "direction": "next" }, },
]
```

これで Windows Terminal の設定も完了です。

あとは、コマンドを実行する都度エスケープシーケンスがプロンプトに追加され、その場所を Windows Terminal がマーキングしますので、`ctrl-up` や `ctrl-down` でコマンドを実行した場所まで画面をスクロールできます。また、コマンド実行結果の上で右クリックして「コマンドの選択」をクリックすると、コマンドと実行結果を簡単に選択できます。

## 参考にした情報

- [Shell integration in the Windows Terminal | Microsoft Learn](https://learn.microsoft.com/en-us/windows/terminal/tutorials/shell-integration)
- [proposals/semantic-prompts.md · master · undefined · GitLab](https://gitlab.freedesktop.org/Per_Bothner/specifications/blob/master/proposals/semantic-prompts.md)
- [zshでOSC 133に対応する](https://zenn.dev/ymotongpoo/articles/20220802-osc-133-zsh)
- [ベル文字 - Wikipedia](https://ja.wikipedia.org/wiki/%E3%83%99%E3%83%AB%E6%96%87%E5%AD%97)
- [zshの本 | 技術評論社](https://gihyo.jp/book/2009/978-4-7741-3864-0)
