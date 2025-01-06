---
# type: docs 
title: Alacritty でテンキーの Enter キーを Enter キーと認識させる方法について
date: 2024-08-20T22:40:45+09:00
featured: false
draft: false
comment: true
toc: false
tags: [備忘録]
archives: 2024/08
---

## 前置き

ターミナルアプリに [Alacritty - A cross-platform, OpenGL terminal emulator](https://alacritty.org/index.html) を使っているのですが、テンキーの Enter キーが `ctrl-j` と認識されてしまうという不具合？ に悩まされていました。

しばらく見て見ぬふりをしていたのですが、地味に不便なので対応しました。

ただ、見つけた対応策はしばらくすると忘れてしまいそうなので、備忘録としてメモします。


## 環境

### OS

```
エディション	Windows 11 Pro
バージョン	23H2
インストール日	2022/07/11
OS ビルド	22631.4108
エクスペリエンス	Windows Feature Experience Pack 1000.22700.1034.0
```

### Alacritty

```powershell
❯ alacritty.exe --version
alacritty 0.13.2 (bb8ea18)
```

## 対応策

`%APPDATA%\alacritty\alacritty.toml` を開いて、以下のキーバインディングの設定を追加します。

```toml
[keyboard]
bindings = [
  { key = "NumpadEnter", mods = 'None', action = "ReceiveChar" },
]
```


## その他

テンキーからの入力については Enter キーに限らず問題があるようで、こんな Issue も投稿されています。

[Can't enable application keypad mode #3720](https://github.com/alacritty/alacritty/issues/3720)

上記の解決策は、この Issue のスレッドにあるこの[投稿](https://github.com/alacritty/alacritty/issues/3720#issuecomment-2100104150) をコピペしたものです。
