---
# type: docs 
title: Klipper の Adaptive Meshes 機能の紹介
date: 2024-03-10T02:13:23+09:00
featured: false
draft: false
comment: true
toc: true
tags: [3Dプリンタ,klipper]
---

## どんな機能？

Klipper に備わっている [Adaptive Meshes](https://www.klipper3d.org/Bed_Mesh.html#adaptive-meshes) 機能を活用することで、印刷前のベッドメッシュレベリングの実施範囲をベッド全体から印刷範囲に限定するという機能です。

印刷範囲に限定してレベリングを実施することでレベリングに要する時間が短くなり、また、測定ポイントが密になってレベリングの精度も上がります。

## 導入方法

### 前提条件

この機能を使うには、[Klipper の Exclude Objects 機能のメモ](https://kankodori-blog.com/posts/2024-02-12/index.html) で紹介した Exclude Objects 機能を有効にしておく必要があります。Exclude Objects 機能を有効化していない方は、まずそちらを設定してください。

また、2024年03月09日時点で、この機能は公式ガイドの [Installation and Configuration](https://www.klipper3d.org/Bed_Mesh.html#adaptive-meshes) で解説されていますが [Releases](https://www.klipper3d.org/Releases.html) には登場していませんので、まだ正式版にはなっていないようです。なお、コミット履歴を見ますと、この機能は 2024年1月27日の [コミット](https://github.com/Klipper3d/klipper/commit/5e3daa6f21d6485e4e757d0df00e01a13c968541) で追加されたようです。そのため、Klipper のバージョンは、このコミットを反映したバージョン以降とする必要があります。

### ツールのインストール

この機能は、印刷のたびに印刷物に合わせて `printer.cfg` の `[bed_mesh]` セクションの `mesh_min` や `mesh_max` や `probe_count` を調整しても実現できますが、そんな面倒くさいことは事実上不可能です。また、印刷物に合わせて Klipper オリジナルの G-Code の `BED_MESH_CALIBRATE` の `mesh_min`、`mesh_max`、`ALGORITHM`、`PROBE_COUNT` オプションに必要な値を渡しても実現できますが、これも相当面倒な作業になります。

そのため、印刷する G-Code を解析してレベリングの実施範囲を算出してくれる [kyleisah/Klipper-Adaptive-Meshing-Purging: A unique leveling solution for Klipper-enabled 3D printers!](https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging) をインストールします。このツールは、G-Code を解析してレベリングすべき範囲とその範囲に合わせた測定ポイントの箇所数の計算して、`BED_MESH_CALIBRATE` の `mesh_min`、`mesh_max`、`ALGORITHM`、`PROBE_COUNT` オプションに必要な値を渡してくれます（`BED_MESH_CALIBRATE` コマンドの上書きもします ）。

このツールをインストールするには、Raspberry pi に SSH で接続して次のコマンドを実行します。

```bash
 cd 
 git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git 
 ln -s ~/Klipper-Adaptive-Meshing-Purging/Configuration printer_data/config/KAMP
 cp ~/Klipper-Adaptive-Meshing-Purging/Configuration/KAMP_Settings.cfg ~/printer_data/config/KAMP_Settings.cfg
```

これでインストールできましたので、次は `KAMP_Settings.cfg` ファイルを編集して設定します。

最低限必要な設定項目は、以下の `include` の中から有効化したい機能を選んでコメントアウトすることです。ひとまず、`#[include ./KAMP/Adaptive_Meshing.cfg]` をコメントアウトすればOKです。

```bash
#[include ./KAMP/Adaptive_Meshing.cfg]
#[include ./KAMP/Line_Purge.cfg]
#[include ./KAMP/Voron_Purge.cfg]
#[include ./KAMP/Smart_Park.cfg]
```

それから、`variable_mesh_margin: 0` の値を変更して、レベリングする範囲を印刷物から何ミリ離した場所にするか決定します。私は印刷物から 5mm 離すことにしましたので、`variable_mesh_margin: 5` としています。

もし、[jlas1/Klicky-Probe: Microswitch probe with magnetic attachement, primarily aimed at CoreXY 3d printers](https://github.com/jlas1/Klicky-Probe) のようにプローブの取り付け・取り外しが必要なプローブを使っている場合、以下の `variable_probe_dock_enable` を `true` にするとともに、取り付け・取り外しのマクロの名前を指定する必要があるようです。私は誘導プローブを使っていますので、この点についてはデフォルトのまま（以下のコードのとおり）としています。

```bash
variable_probe_dock_enable: False
variable_attach_macro: 'Attach_Probe'
variable_detach_macro: 'Dock_Probe'
```

あとは、`printer.cfg` に `[include KAMP_Settings.cfg]` を追加するとともに、Start G-Code に `BED_MESH_CALIBRATE=default` と `BED_MESH_PROFILE LOAD=default` を追加して通常どおり印刷すればOKのはずです。

## 実際の動作

実際の動作は次のとおりです。レベリングする範囲がベッド全体ではなく印刷する範囲に限定されているのが分かると思います。

{{< video src="klipper_adaptive_mesh_leveling.mp4" type="video/webm" preload="auto" >}}

## 補足

レベリングの範囲は、印刷する G-Code をアップロードした際に Klipper が自動で追加する `EXCLUDE_OBJECT_DEFINE NAME=hoge CENTER=xxx.xx,yyy.yy POLYGON=[[xx1.x,yy1.y],[xx2.x,yy2.y],[xx3.x,yy3.y],[xx4.x,yy4.y]]` というコードから印刷物の範囲を割り出して、そこに `variable_mesh_margin: x` で設定したマージンを追加した値になるようです。

また、測定箇所数は、`ベッド全体を測定する際の測定数 * 測定範囲の距離 / ベッド全体を測定する際の測定範囲の距離 + 1` としているようです。ただし、ソースコードを見ますと、最低でも 3x3 箇所は測定する設定になっています。
