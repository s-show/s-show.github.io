---
# type: docs 
title: Klipper の Exclude Objects 機能のメモ
date: 2024-02-12T16:11:03+09:00
featured: false
draft: false
comment: true
toc: true
tags: [3Dプリンタ,klipper]
archives: 2024/02
---

## どんな機能なのか？

複数の `stl` ファイルを同時に印刷している際に、途中で一部のファイルだけ印刷を中止できる機能です。具体的には、6つのファイルを同時に印刷していたら1つだけビルドプレートから剥がれてしまったという場合に、その1つだけ印刷を中止して残りの5つは最後まで印刷するという機能です。これにより、印刷に失敗したパーツの印刷を続けて思わぬトラブルを引き起こす心配がなくなりますし、無駄なフィラメントの消費も抑えられますので、非常に有用な機能です。

この機能を使うには、Klipper、Moonraker およびスライサーで所要の設定を行う必要がありますが、手順を紹介した日本語の記事が見当たらなかったので、備忘録代わりにメモします。

なお、公式ガイドは [Exclude Objects - Klipper documentation](https://www.klipper3d.org/Exclude_Object.html) で、この記事は2024年2月12日時点の情報を元に書いています。

## 対応バージョン

Exclude Objects 機能を使うには、Klipper などのバージョンを以下のバージョン以上にアップデートする必要があります。
<dl>
	<dt>Klipper</dt>
	<dd>v0.10.0-438</dd>
	<dt>Moonraker</dt>
	<dd>v0.7.1-445</dd>
    <dt>Mainsail</dt>
    <dd><a href="https://github.com/mainsail-crew/mainsail/releases/tag/v2.1.0">v2.1.0</a></dd>
    <dt>Fluidd</dt>
    <dd><a href="https://github.com/fluidd-core/fluidd/blob/develop/CHANGELOG.md#1190-2022-07-10">v1.19.0</a>
</dd>
</dl>

また、この処理は結構重い処理ということなので、Raspberry pi zero のような非力なシングルボードコンピュータでは厳しいようです。

{{% alert info %}}
Klipper と Moonraker のバージョンについては <a href="https://docs.mainsail.xyz/overview/features/exclude-objects">Exclude Objects - Mainsail</a> に記載された情報を元に記載していますが、公式情報で確認した範囲では、Klipper は <a href="https://www.klipper3d.org/Releases.html#klipper-0110">v0.11.0</a> で正式に対応したようです。Moonraker については、CHANGELOG などで対応時期を確認することはできませんでしたが、公式ドキュメントの Github のコミット履歴を見ると、2021年12月5日の<a href="https://github.com/Arksine/moonraker/commit/b3d2307d36a7e8c72b283309bd25617a9dd36759">コミット</a>でこの機能に関する説明が追加されていますので、この頃に対応したものと思われます。
{{% /alert %}}

## 必要な設定

この機能を使うための Klipper、Moonraker およびスライサーの設定は次のとおりです。

### Klipper の設定

`printer.cfg` に `[exclude_object]` セクションを追加するだけです。

```diff
# printer.cfg
+ [exclude_object]
```
### Moonraker の設定

`moonraker.conf` の `[file_manager]` セクションに `enable_object_processing: true` を追加します。Moonraker のバージョンによっては、`enable_object_processing: false` という設定が最初から存在しているかもしれません。その場合、`false` を `true` に変えればOKです。

```diff
# moonraker.conf
[file_manager]
- enable_object_processing: false
+ enable_object_processing: true
```

### Mainsail や Fluidd の設定

Klipper と Moonraker を設定すれば Mainsail や Fluidd の設定は不要です。

### スライサーの設定

PrusaSlicer の場合、「プリント設定 → 出力オプション → オブジェクトにラベルを付ける」と選択して、ドロップダウンメニューから「OctoPrint のコメント」を選択すればOKです。

{{< bsimage src="./image/prusaslicer.png" title="PrusaSlicerの設定" >}}

SuperSlicerの場合、「プリント設定 → 出力オプション」と選択して、「オブジェクトにラベルを付ける」というチェックボックスにチェックを付ければOKです。

{{< bsimage src="./image/superslicer.png" title="SuperSlicerの設定" >}}

それから、印刷したい `stl` ファイルをプレートに並べてスライスし、G-code をプリンタに送信します。スライスは普段どおり行なえばOKです。

{{< bsimage src="./image/plate.png" title="スライス画面" >}}

## この機能の使い方

必要な設定が完了していれば、Mainsail や Fluidd の印刷状況を示すボックスにキャンセルするためのボタンが追加されているはずです（印刷前の時点では表示されていません）。ちなみに、この画面は Fluidd の場合のものです。

{{< bsimage src="./image/cancelbutton.png" title="個別キャンセルのボタン" >}}

印刷が始まって印刷を中止したいパーツが出てきましたら、上記のキャンセルボタンをクリックします。

すると、現在印刷しているパーツのリストが表示されますので、印刷を中止したいパーツの右側にあるストップボタンをクリックします。

{{< bsimage src="./image/stopprint.png" title="印刷中のパーツリスト" >}}
  
すると、印刷を中止するか尋ねられますので、Yes をクリックします。

{{< bsimage src="./image/dialog.png" title="確認画面" >}}

これで、選択したパーツの印刷が中止されますので、あとは他のパーツの印刷が終わるのを待つだけです。

{{< bsimage src="./image/result.png" title="キャンセル後の画面" >}}

## 実際の印刷の様子

この機能を使って3つのパーツのうち1つのパーツの印刷を中止した時の印刷の様子を撮影しましたので、参考までに掲載します。

{{< video src="./image/exclude_object.mp4" type="video/webm" preload="auto" >}}
