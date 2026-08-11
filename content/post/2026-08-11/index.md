---
title: "GitHub に SSH キーを追加する方法 " # Title of the blog post.
date: 2026-08-11T21:04:46+09:00 # Date of post creation.
featured: true # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
# menu: main
tags: [git]
comment: true # Disable comment if false.
archives: 2026/8
---

## 前置き

この処理をするたびに何度も公式リファレンスを探し出して読んでいるので、備忘録として一連のコマンドをメモします。

なお、ここで紹介しているコマンドは、Ubuntu Server 26.04 で実行したものです。

## 実際のコマンド

実際に入力するコマンドは以下のとおりです。なお、それぞれのコマンドの意味はコメントのとおりです。

```bash
// 既存の SSH キーの確認
> ls -al ~/.ssh
total 12
drwx------ 2 user user 4096 Aug  3 13:42 .
drwxr-x--- 7 user user 4096 Aug  3 13:42 ..
-rw------- 1 user user    0 Aug  2 12:53 authorized_keys
-rw-r--r-- 1 user user  142 Aug  3 13:42 known_hosts
```

```bash
// 新しい SSH キーを生成する
> ssh-keygen -t ed25519 -C "your_email@example.com"

Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/user/.ssh/id_ed25519):
Enter passphrase for "/home/user/.ssh/id_ed25519" (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/user/.ssh/id_ed25519
Your public key has been saved in /home/user/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx your_email@example.com
The key's randomart image is:
+--[ED25519 256]--+
|                 |
|                 |
|                 |
|                 |
|                 |
|                 |
|                 |
|                 |
|                 |
+----[SHA256]-----+
```

```bash
// バックグラウンドでssh-agentを開始する
> eval "$(ssh-agent -s)"
Agent pid 16565
```

```bash
// ssh-agent に追加するのは「秘密鍵」（拡張子なしのファイル）
> ssh-add ~/.ssh/id_ed25519
```

```bash
// GitHub に認証のために公開鍵を登録する（`.pub` ファイル）
> gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication
HTTP 404: Not Found (https://api.github.com/user/keys?per_page=xxx)
This API operation needs the "admin:public_key" scope. To request it, run:  gh auth refresh -h github.com -s admin:public_key

// 登録処理がエラーになり、エラーメッセージに gh の認証をリフレッシュせよとあるので、
// 指示どおり gh の認証をリフレッシュする
> gh auth refresh -h github.com -s admin:public_key

! First copy your one-time code: 0000-0000
Press Enter to open github.com in your browser...
! Failed opening a web browser at https://github.com/login/device
  exec: "xdg-open,x-www-browser,www-browser,wslview": executable file not found in $PATH
  Please try entering the URL in your browser manually
✓ Authentication complete.

// 再度登録コマンドを実行する
> gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication
✓ Public key added to your account  # 公開鍵が GitHub に登録される
```

```bash
// 同じ公開鍵をコミット署名用にも登録する
> gh ssh-key add ~/.ssh/id_ed25519.pub --type signing
HTTP 404: Not Found (https://api.github.com/user/ssh_signing_keys?per_page=xxx)
This API operation needs the "admin:ssh_signing_key" scope. To request it, run:  gh auth refresh -h github.com -s admin:ssh_signing_key

// 登録処理がエラーになり、エラーメッセージに gh の認証をリフレッシュせよとあるので、
// 指示どおり gh の認証をリフレッシュする
> gh auth refresh -h github.com -s admin:ssh_signing_key

! First copy your one-time code: 0000-0000
Press Enter to open github.com in your browser...
! Failed opening a web browser at https://github.com/login/device
  exec: "xdg-open,x-www-browser,www-browser,wslview": executable file not found in $PATH
  Please try entering the URL in your browser manually
✓ Authentication complete.

// 再度登録コマンドを実行する
> gh ssh-key add ~/.ssh/id_ed25519.pub --type signing
✓ Public key added to your account  # 公開鍵が GitHub に登録される
```

```bash
// SSH で接続できるかチェック
> ssh -T git@github.com
Enter passphrase for key '/home/user/.ssh/id_ed25519':
Hi user! You've successfully authenticated, but GitHub does not provide shell access.
```


## その他参考

### `~/.ssh` が存在しない場合

SSH 関連の設定を行っていない場合、`~/.ssh` が存在しない可能性があります。その場合、`ssh-keygen` の手続きに進めば OK です。

### コミット署名にはローカルの git 設定も必要

`gh ssh-key add --type signing` は、GitHub 側に「この公開鍵による署名を信頼する」と**登録するだけ**です。実際にコミットへ署名するかどうかはローカルの git 設定で決まるので、以下も設定しないとコミットに署名が付かず、`Verified` 表示は出ません。

```bash
// 署名方式に SSH を使う
> git config --global gpg.format ssh

// 署名に使う鍵を指定する（ここでも指定するのは公開鍵）
> git config --global user.signingkey ~/.ssh/id_ed25519.pub

// 全てのコミットに自動で署名する（個別に署名するなら git commit -S でもよい）
> git config --global commit.gpgsign true

// タグにも署名する場合
> git config --global tag.gpgsign true
```

一方 `--type authentication` の方は、ssh クライアントが `~/.ssh/id_ed25519` を自動的に使うため、登録するだけで機能します。ここが signing と非対称で分かりにくいところです。

### `authentication` と `signing` の違い

`gh ssh-key add` の `authentication` と `signing` の違いは以下のとおりです。


| 項目     | Authentication (認証)            | Signing (署名)                   |
|----------|----------------------------------|----------------------------------|
| 目的     | リポジトリへのアクセス権限の証明 | コミット内容の本人の証明         |
| 主な効果 | push や pull が可能になる        | GitHub上で Verified 表示が出る   |
| 必須度   | SSH接続を利用するなら必須        | セキュリティ要件が高い場合に利用 |
| 登録だけで機能するか | する                 | しない（上記の git 設定が必要）  |


## 参考にした情報

公式リファレンス
- [Checking for existing SSH keys - GitHub Docs](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/checking-for-existing-ssh-keys)
- [新しい SSH キーを生成して ssh-agent に追加する - GitHubドキュメント](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [GitHub アカウントへの新しい SSH キーの追加 - GitHubドキュメント](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?tool=cli)

