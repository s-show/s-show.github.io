---
# type: docs 
title: OpenSCAD で作成されたデータを Fusion360 で編集する方法
date: 2023-03-13T21:34:03+09:00
draft: false
comment: true
toc: true
tags: [3Dプリンタ, 備忘録]
---

## 前置き

先日、OpenSCAD で作成された3Dモデルを一部改変して3Dプリンタで出力したいことがあり、そのとき OpenSCAD で作成されたデータを `.step` ファイルに変換して Fusion360 で編集する方法を見つけたのですが、日本語で変換方法を説明しているウェブページが見つからなかったため、備忘録を兼ねて手順をまとめます。


## 環境

OS
: Windows11 Pro 22H2

Fusion360
: 2.0.15509 x86_64

OpenSCAD
: version 2021.01

FreeCAD
: version 0.18


## 大まかな手順

1. 変換したい OpenSCAD データを OpenSCAD で開いて `.csg` ファイルとしてエクスポートする
1. 1.でエクスポートした `.csg` ファイルを FreeCAD で開いて `.step` ファイルとしてエクスポートする
1. 2.でエクスポートした `.step` ファイルを Fusion360 で開く

## 具体的な手順

### OpenSCAD での作業

まず、対象となる OpenSCAD データを OpenSCAD で開いてレンダリングします。

レンダリングしたら File > Export > Export as CSG... の順番で選択して対象データを `.csg` ファイルとしてエクスポートします。

### FreeCAD での作業

まず、OpenSCAD でエクスポートした `.csg` ファイルを FreeCAD で開きます。

次に、表示 > ワークベンチ > OpenSCAD の順番で選択してワークベンチを OpenSCAD に変更します。ワークベンチを変更しなくてもエクスポートできますが、エクスポートしたデータを開いたら元の形と全く違うデータになったりします。

それから、`ctrl-a` でデータを全選択し、ファイル > エクスポート の順番で選択してファイル保存ダイアログが開いたら、ファイルの種類を STEP with colors (*.step *.stp) に変更して好きな名前でファイルをエクスポートします

### Fusion360 での作業

ファイルを開く > マイコンピュータから開く... の順番で選択してダイアログ画面を表示したら、FreeCAD でエクスポートした `.step` ファイルを選択して開きます。

以上の作業で OpenSCAD で作成されたデータを Fusion360 で編集できるようになります。


## 参考にしたサイト

[How to import OpenSCAD file into Fusion360 as a solid body - Autodesk Community](https://forums.autodesk.com/t5/fusion-360-manage-ideas/how-to-import-openscad-file-into-fusion360-as-a-solid-body/idi-p/10174834)
[OpenSCAD User Manual/STL Export - Wikibooks, open books for an open world](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/STL_Export)

