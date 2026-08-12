---
title: "Ubuntu Server で LVM を拡張する方法" # Title of the blog post.
date: 2026-08-13T01:04:46+09:00 # Date of post creation.
featured: true # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
# menu: main
tags: [linux, cli]
comment: true # Disable comment if false.
archives: 2026/8
---

## 前置き

ローカル LLM を運用していますが、普段使いのデスクトップPCで LLM を動かすとゲームなどに支障が生じてしまうので、思い切ってローカルLLM 専用機を導入することにしました。専用機の構成は以下のとおりです。

- マザーボード: MPG Z890 CARBON WIFI
- CPU: Intel Core Ultra 7 270K Plus
- GPU: AMD Radeon AI PRO R9700
- メモリ: CORSAIR VENGEANCE DDR5 64GB(32GBx2)
- OS: Ubuntu Server26.04
- SSD: Acer Predator M.2 SSD 2TB GM6 NVMe2.0 2280 PCIe Gen4×4 を2枚（2枚とも昨今の値上がり前に購入）

この構成で無事に OS が起動することを確認してから、[ggml-org/llama.cpp: LLM inference in C/C++](https://github.com/ggml-org/llama.cpp) などのツールをインストールし、モデルをデスクトップPCからコピーしました。ところが、モデルを3個コピーした時点でディスクの空き容量が無くなってしまいました。

そのときのディスク使用状況は以下のとおりで、SSD は2TBなのに `/` の割り当ては 100GB になっていました。

```bash
> duf
╭─────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ 3 local devices                                                                                     │
├────────────┬───────┬───────┬───────┬────────────────────────────┬──────┬────────────────────────────┤
│ MOUNTED ON │  SIZE │  USED │ AVAIL │            USE%            │ TYPE │ FILESYSTEM                 │
├────────────┼───────┼───────┼───────┼────────────────────────────┼──────┼────────────────────────────┤
│ /          │ 97.9G │ 92.9G │    0B │ ██████████████████▌  94.9% │ ext4 │ /dev/ubuntu--vg-ubuntu-/lv │
│ /boot      │  1.9G │ 96.5M │  1.7G │ ▌                     5.0% │ ext4 │ /dev/nvme1n1p2             │
│ /boot/efi  │  1.0G │  6.3M │  1.0G │                       0.6% │ vfat │ /dev/nvme1n1p1             │
╰────────────┴───────┴───────┴───────┴────────────────────────────┴──────┴────────────────────────────╯
```

これでは使い物になりませんので、`/` を拡張することにしました。その作業について、今後の備忘録とするためにメモします。

## 実際の作業

M.2 & NVME 接続の 2TB SSD を2枚取り付けているので、まず、それらの SSD の認識状況を確認するため `lsblk` コマンドでブロックデバイスを一覧表示します。

```bash
bash
> lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
nvme1n1                   259:0    0  1.9T  0 disk
├─nvme1n1p1               259:2    0    1G  0 part /boot/efi
├─nvme1n1p2               259:3    0    2G  0 part /boot
└─nvme1n1p3               259:4    0  1.9T  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0  100G  0 lvm  /
nvme0n1                   259:1    0  1.9T  0 disk
```

また、PV (Phisycal Volume) の状況を確認するため、`pvdisplay` コマンドも実行します。

```bash
> sudo pvdisplay
  --- Physical volume ---
  PV Name               /dev/nvme1n1p3
  VG Name               ubuntu-vg
  PV Size               1.86 TiB / not usable 0
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              487597
  Free PE               0
  Allocated PE          487597
  PV UUID               HeXIAR-qGCF-dmDu-iBif-lJm1-1wzc-MSMK58
```

2つの結果を見ますと、`nvme1n1` がシステムディスクとして使われており、そのうち、`nvme1n1p3` パーティションの容量が1.9TBあり、PV として使われていることが分かります（`pvdisplay` は作業後に実施していますので、Free PE が 0 になっています）。そして、`nvme1n1p3` の容量1.9TBのうち `/` に割り当てられているのは 100GB なので、残りが未使用であることが分かります。[^1]

[^1]: nvme0n1 はまだパーティション未作成の状態で、今回の作業の対象外としています。

続いて、`vgdisplay` コマンドを使ってボリュームグループの情報を取得します。

```bash
> sudo vgdisplay
  --- Volume group ---
  VG Name               ubuntu-vg
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               1.86 TiB
  PE Size               4.00 MiB
  Total PE              487597
  Alloc PE / Size       25600 / 100.00 GiB
  Free  PE / Size       461997 / 1.76 TiB
  VG UUID               HfOUv4-xt1I-qo9u-Butv-3XNi-KkV1-IwjTfv
```

`Free PE / Size` が `461997 / 1.76 TiB` となっているので、ボリュームグループに未使用領域が 1.76TB あることが分かります。この未使用領域を使って LV を拡張するため、以下のとおり `lvextend` コマンドを実行します。

```bash
> sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
  Size of logical volume ubuntu-vg/ubuntu-lv changed from 100.00 GiB (25600 extents) to 1.86 TiB (487597 extents).
  Logical volume ubuntu-vg/ubuntu-lv successfully resized.
```

`Size of logical volume ubuntu-vg/ubuntu-lv changed from 100.00 GiB (25600 extents) to 1.86 TiB (487597 extents).` と表示されましたので、LV が 100GB から 1.86TB に拡張されました。拡張後のボリュームグループの情報は以下のとおりです。

```bash
> sudo vgdisplay
  --- Volume group ---
  VG Name               ubuntu-vg
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               1.86 TiB
  PE Size               4.00 MiB
  Total PE              487597
  Alloc PE / Size       487597 / 1.86 TiB
  Free  PE / Size       0 / 0
  VG UUID               HfOUv4-xt1I-qo9u-Butv-3XNi-KkV1-IwjTfv
```

最後に、ファイルシステム（Ubuntu Server のデフォルトは ext4）をリサイズするため、`resize2fs` を以下のとおり実行して、LV の実サイズ一杯まで拡張します。

```bash
> sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
resize2fs 1.47.2 (1-Jan-2025)
Filesystem at /dev/ubuntu-vg/ubuntu-lv is mounted on /; on-line resizing required
old_desc_blocks = 13, new_desc_blocks = 239
The filesystem on /dev/ubuntu-vg/ubuntu-lv is now 499299328 (4k) blocks long.
```

拡張後のディスクの使用状況は以下のとおりで、`/` の空き容量が大幅に増加しています。

```bash
> duf
╭───────────────────────────────────────────────────────────────────────────────────────────────────╮
│ 3 local devices                                                                                   │
├────────────┬──────┬───────┬───────┬───────────────────────────┬──────┬────────────────────────────┤
│ MOUNTED ON │ SIZE │  USED │ AVAIL │            USE%           │ TYPE │ FILESYSTEM                 │
├────────────┼──────┼───────┼───────┼───────────────────────────┼──────┼────────────────────────────┤
│ /          │ 1.8T │ 73.1G │  1.7T │ ▌                    3.9% │ ext4 │ /dev/ubuntu--vg-ubuntu-/lv │
│ /boot      │ 1.9G │ 96.5M │  1.7G │ ▌                    5.0% │ ext4 │ /dev/nvme1n1p2             │
│ /boot/efi  │ 1.0G │  6.3M │  1.0G │                      0.6% │ vfat │ /dev/nvme1n1p1             │
╰────────────┴──────┴───────┴───────┴───────────────────────────┴──────┴────────────────────────────╯
```
