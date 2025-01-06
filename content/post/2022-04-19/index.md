---
title: "sudo apt update で Fish のリポジトリキーが不正と表示される件について"
date: 2022-04-19T00:15:04+09:00
draft: false
tags: [備忘録]
archives: 2022/04
---


## 前置き

MainsailOS をインストールしている Raspberry Pi で `sudo apt update` を実行したら `The following signatures were invalid: EXPKEYSIG 2CE2AC08D880C8E4 shells:fish OBS Project <shells:fish@build.opensuse.org>` と表示されるようになりました。

```bash
> sudo apt update
Get:1 https://pkgs.tailscale.com/stable/raspbian buster InRelease
Hit:2 http://archive.raspberrypi.org/debian buster InRelease
Get:3 http://raspbian.raspberrypi.org/raspbian buster InRelease [15.0 kB]
Hit:4 http://download.opensuse.org/repositories/shells:/fish/Debian_10  InRelease
Hit:5 https://deb.nodesource.com/node_16.x buster InRelease
Err:4 http://download.opensuse.org/repositories/shells:/fish/Debian_10  InRelease
  The following signatures were invalid: EXPKEYSIG 2CE2AC08D880C8E4 shells:fish OBS Project <shells:fish@build.opensuse.org>
Get:6 http://raspbian.raspberrypi.org/raspbian buster/main armhf Packages [13.0 MB]
0% [6 Packages 6,114 kB/13.0 MB 47%]                                                                 40.1 kB/s 2min 51sdebug1: client_input_channel_req: channel 0 rtype keepalive@openssh.com reply 1
0% [6 Packages 12.9 MB/13.0 MB 99%]                                                                        28.5 kB/s 3sdebug1: client_input_channel_req: channel 0 rtype keepalive@openssh.com reply 1
Fetched 13.0 MB in 6min 19s (34.4 kB/s)
Reading package lists... Done
Building dependency tree
Reading state information... Done
3 packages can be upgraded. Run 'apt list --upgradable' to see them.
W: An error occurred during the signature verification. The repository is not updated and the previous index files will be used. GPG error: http://download.opensuse.org/repositories/shells:/fish/Debian_10  InRelease: The following signatures were invalid: EXPKEYSIG 2CE2AC08D880C8E4 shells:fish OBS Project <shells:fish@build.opensuse.org>
W: Failed to fetch http://download.opensuse.org/repositories/shells:/fish/Debian_10/InRelease  The following signatures were invalid: EXPKEYSIG 2CE2AC08D880C8E4 shells:fish OBS Project <shells:fish@build.opensuse.org>
W: Some index files failed to download. They have been ignored, or old ones used instead.
```

これではアップデートに支障が生じるので解決策を探したところ、公式の Github の Issues で解決策が見つかりましたので、参考のためにシェアします。

## 解決策の概要

簡単にまとめると次のとおりです。

1. 期限切れになった既存のリポジトリキーを削除
2. 新しいキーを登録
3. `sudo apt update` を実行

## 具体的な手順

### 既存のリポジトリキーの確認

既存のリポジトリキーは、次のコマンドで確認できます。一番下の `/etc/apt/trusted.gpg.d/shells_fish.gpg` が期限切れ（expired）になったキーです。

```bash
> sudo apt-key list
/etc/apt/trusted.gpg
--------------------
pub   rsa2048 2012-04-01 [SC]
      A0DA 38D0 D76E 8B5D 6388  7281 9165 938D 90FD DD2E
uid           [ unknown] Mike Thompson (Raspberry Pi Debian armhf ARMv6+VFP) <mpthompson@gmail.com>
sub   rsa2048 2012-04-01 [E]

pub   rsa2048 2012-06-17 [SC]
      CF8A 1AF5 02A2 AA2D 763B  AE7E 82B1 2992 7FA3 303E
uid           [ unknown] Raspberry Pi Archive Signing Key
sub   rsa2048 2012-06-17 [E]

pub   rsa4096 2020-02-25 [SC]
      2596 A99E AAB3 3821 893C  0A79 458C A832 957F 5868
uid           [ unknown] Tailscale Inc. (Package repository signing key) <info@tailscale.com>
sub   rsa4096 2020-02-25 [E]

/etc/apt/trusted.gpg.d/shells_fish.gpg
--------------------------------------
pub   rsa2048 2013-10-08 [SC] [expired: 2022-04-12]
      24A6 3B31 CAB4 1B33 EC48  801E 2CE2 AC08 D880 C8E4
uid           [ expired] shells:fish OBS Project <shells:fish@build.opensuse.org>
```

### 期限切れになったリポジトリキーの削除

期限切れになったリポジトリキーは、次のコマンドで削除できます。

```bash
> sudo apt-key del 2CE2AC08D880C8E4
OK
```

削除後のリポジトリキーのリストを確認すると、 `/etc/apt/trusted.gpg.d/shells_fish.gpg` が削除されていることが確認できます。

```bash
> sudo apt-key list
/etc/apt/trusted.gpg
--------------------
pub   rsa2048 2012-04-01 [SC]
      A0DA 38D0 D76E 8B5D 6388  7281 9165 938D 90FD DD2E
uid           [ unknown] Mike Thompson (Raspberry Pi Debian armhf ARMv6+VFP) <mpthompson@gmail.com>
sub   rsa2048 2012-04-01 [E]

pub   rsa2048 2012-06-17 [SC]
      CF8A 1AF5 02A2 AA2D 763B  AE7E 82B1 2992 7FA3 303E
uid           [ unknown] Raspberry Pi Archive Signing Key
sub   rsa2048 2012-06-17 [E]

pub   rsa4096 2020-02-25 [SC]
      2596 A99E AAB3 3821 893C  0A79 458C A832 957F 5868
uid           [ unknown] Tailscale Inc. (Package repository signing key) <info@tailscale.com>
sub   rsa4096 2020-02-25 [E]
```

### 新しいリポジトリキーの登録

新しいリポジトリキーは、次のコマンドで登録できます。このコマンドは、最初に触れた Github の Issues で提案されたコマンドを Debian10 向けに修正したものです。

```bash
curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_10/Release.key |gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
```

新しいリポジトリキーを登録した後のキーリストは次のとおりです。 `/etc/apt/trusted.gpg.d/shells_fish_release_3.gpg` が登録されていることが確認できます。

```bash
> sudo apt-key list
/etc/apt/trusted.gpg
--------------------
pub   rsa2048 2012-04-01 [SC]
      A0DA 38D0 D76E 8B5D 6388  7281 9165 938D 90FD DD2E
uid           [ unknown] Mike Thompson (Raspberry Pi Debian armhf ARMv6+VFP) <mpthompson@gmail.com>
sub   rsa2048 2012-04-01 [E]

pub   rsa2048 2012-06-17 [SC]
      CF8A 1AF5 02A2 AA2D 763B  AE7E 82B1 2992 7FA3 303E
uid           [ unknown] Raspberry Pi Archive Signing Key
sub   rsa2048 2012-06-17 [E]

pub   rsa4096 2020-02-25 [SC]
      2596 A99E AAB3 3821 893C  0A79 458C A832 957F 5868
uid           [ unknown] Tailscale Inc. (Package repository signing key) <info@tailscale.com>
sub   rsa4096 2020-02-25 [E]

/etc/apt/trusted.gpg.d/shells_fish_release_3.gpg
------------------------------------------------
pub   rsa2048 2013-10-08 [SC] [expires: 2024-06-07]
      24A6 3B31 CAB4 1B33 EC48  801E 2CE2 AC08 D880 C8E4
uid           [ unknown] shells:fish OBS Project <shells:fish@build.opensuse.org>
```

### `sudo apt update` の実行

新しいリポジトリキーを登録しましたので、 `sudo apt update` を実行して問題がないか確認します。 できます。このコマンドは、最初に触れた Github の Issues で提案されたコマンドを Debian10 向けに修正したものです。

```bash
> sudo apt update
Hit:1 http://download.opensuse.org/repositories/shells:/fish/Debian_10  InRelease
Hit:2 https://deb.nodesource.com/node_16.x buster InRelease
Hit:3 http://archive.raspberrypi.org/debian buster InRelease
Hit:4 http://raspbian.raspberrypi.org/raspbian buster InRelease
Get:5 https://pkgs.tailscale.com/stable/raspbian buster InRelease
Fetched 5,543 B in 2s (2,367 B/s)
Reading package lists... Done
Building dependency tree
Reading state information... Done
3 packages can be upgraded. Run 'apt list --upgradable' to see them.
```

無事に問題が発生することなくアップデートできていることが確認できました。

---

参考にしたサイト

[https://github.com/fish-shell/fish-shell/issues/8869](https://github.com/fish-shell/fish-shell/issues/8869)
