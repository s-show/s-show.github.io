---
# type: docs 
title: WSL2 で生成した SSH の鍵を Windows11 で使う方法
date: 2022-11-20T12:16:58+09:00
featured: false
draft: false
comment: true
toc: true
reward: true
pinned: false
carousel: false
series:
tags: [備忘録, プログラミング]
images: []
---

## 前置き

Github でパスワードを用いた HTTPS 接続が 2021年8月13日に廃止されたことに伴い、WSL2 で SSH 接続のための秘密鍵と公開鍵のペアを作成して各種操作に利用していました。

しかし、WSL2 だけではなく Windows11 でも Github にアクセスする必要が出てきたので、WSL2 で生成した鍵のペアを Windows11 でも使えるようにしました。

Windows11 or 10 で生成した鍵のペアを WSL2 で使えるようにする方法はいくつか見つかりましたが、その反対の方法を解説したページが見つからなかったため、手順を備忘録として公開します。

## 環境

OS: Windows11 Pro (10.0.22621 ビルド 22621)

Git Bash: mintty 3.6.1 (x86_64-pc-msys) [Windows 22621]

Git: git version 2.37.3.windows.1

秘密鍵と公開鍵の保存場所: `~/.ssh/id_ed25519` `~/.ssh/id_ed25519.pub`

## 手順

Github の公式ガイドに沿って作業を進めていきますが、既に鍵のペアを生成しているため、秘密鍵を ssh-agent に登録するところから作業を開始します。

まず、ssh-agent を起動するため、Git Bash を起動して `eval "$(ssh-agent -s)"` コマンドを実行します。ssh-agent が起動すれば `Agent pid 59566` という形で PID が返ってきます。

ssh-agent が起動したら、秘密鍵を ssh-agent に登録するため `ssh-add ~/.ssh/id_ed25519` コマンドを実行します。

次に公開鍵を Github に登録するため、公開鍵の内容をクリップボードにコピーします。クリップボードへのコピーは `clip < ~/.ssh/id_ed25519.pub` コマンドでOKです。

ここまで進んだら [github.com](http://github.com) にアクセスして右上のアイコンから Settings → SSH and GPG keys と進み、New SSH key をクリックして公開鍵を登録する画面を開きます。

あとは、Title に適当なタイトルを入力し、Key 欄に先ほどクリップボードにコピーした公開鍵の内容をペーストし、Add SSH key をクリックして公開鍵を Github に登録します。

最後に、SSH でアクセスできるか確認するため、 `ssh -T git@github.com` コマンドを実行して「Hi (username)! You've successfully authenticated, but GitHub does not provide shell access.」と表示されれば OK です。

-—

参考ページ

Github の公式ガイド -> [Generating a new SSH key and adding it to the ssh-agent - GitHub Docs](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent)

パスワードを用いた HTTPS 接続停止のアナウンス -> [Token authentication requirements for Git operations | The GitHub Blog](https://github.blog/2020-12-15-token-authentication-requirements-for-git-operations/)