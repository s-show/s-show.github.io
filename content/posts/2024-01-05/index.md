---
# type: docs 
title: 3Dプリンタの造形物を顕微鏡で観察した結果
date: 2024-5T01:51:48+09:00
featured: false
draft: false
comment: true
toc: true
tags: [3Dプリンタ]
---

## 前置き

新しいフィラメントを使うときは、そのフィラメントに適した温度・Pressure Advance・射出率・リトラクション長を見つけ出すために色々とテストしますが、テスト印刷した造形物を顕微鏡で観察してみたくなりましたので、観察結果を紹介します。

ちなみに、テストしたフィラメントは次の2つです。

- [Amazon.co.jp: GratKit PLAフィラメント 3Dプリンター フィラメント 1.75mm 寸法精度+/-0.03mm ほとんどのFDM式プリンターに対応 1KG/ロール オレンジ : 産業・研究開発用品](https://amzn.asia/d/fLsD8om)
- [Amazon.co.jp: GratKit PLAフィラメント 3Dプリンター フィラメント 1.75mm 寸法精度+/-0.03mm ほとんどのFDM式プリンターに対応 1KG/ロール グレー : 産業・研究開発用品](https://amzn.asia/d/6x4KZUl)

また、使用した顕微鏡はこちらの商品です。

[Amazon.co.jp: Andonstar AD207 USBデジタル顕微鏡 AD207 7インチLCDディスプレイと3Dビジュアルエフェクト付き 回路基板修理サービングツール : おもちゃ](https://amzn.asia/d/cL8wO6y)

## 射出率調整の造形物の観察結果

私は、射出率を [Extrusion Multiplier | Ellis’ Print Tuning Guide](https://ellis3dp.com/Print-Tuning-Guide/articles/extrusion_multiplier.html) で紹介されている方法で調整しています。この方法を簡単に紹介すると、300x300x30mm のキューブを射出率を変えながら印刷し、その結果を目視で見比べて適切な射出率を選び出すというものです。

そこで、以下のとおりキューブを5つ並べて各キューブの射出率を90%・92%・94%・96%・98%・100%に設定し、その結果を顕微鏡と手触りで確認しました。

{{< bsimage src="./image/screenshot1.png" title="スライサーの画面" >}}

顕微鏡で印刷物の上面を撮影した結果は次のとおりです。写真だと分かりにくいですが、射出率が増えるに従って表面がデコボコしてくる感じになります。また、射出率を80%まで下げると、肉眼で分かる穴が空くようになります（矢印で示した場所）。

{{< bsimage src="./image/EM/ExtrusionMultiplier_90_2.JPEG" title="射出率90%" >}}
{{< bsimage src="./image/EM/ExtrusionMultiplier_92_2.JPEG" title="射出率92%" >}}
{{< bsimage src="./image/EM/ExtrusionMultiplier_94_2.JPEG" title="射出率94%" >}}
{{< bsimage src="./image/EM/ExtrusionMultiplier_96_2.JPEG" title="射出率96%" >}}
{{< bsimage src="./image/EM/ExtrusionMultiplier_98_2.JPEG" title="射出率98%" >}}
{{< bsimage src="./image/EM/ExtrusionMultiplier_100_2.JPEG" title="射出率100%" >}}
{{< bsimage src="./image/EM/ExtrusionMultiplier_80_2.JPEG" title="射出率80%" >}}

顕微鏡写真で見れば肉眼より正確に判断できるかと思ったのですが、肉眼で虫眼鏡で向きを変えながら見る方法でも顕微鏡と同じ結果になりましたので、キャリブレーションのたびに顕微鏡を取り出してくる必要はなさそうです。ちなみに、今回のキャリブレーションの結果、射出率は96%とすることにしました。

## Pressure Advance の調整の観察結果

Pressure Advance の調整は、[Ellis' Pressure Advance / Linear Advance Calibration Tool](https://ellis3dp.com/Pressure_Linear_Advance_Tool/) で G-code を生成して印刷する方法で調整しています。Klipper 公式の方法より短時間かつ結果が読み取りやすいので、このサイトを見つけてからずっとこの方法で調整しています。

生成した G-Code を印刷した結果は次のとおりです。射出率のときは違いが分かりにくかったですが、こちらは違いがよく分かります。

{{< bsimage src="./image/PA/IMG180101-010439-000087F.jpeg" title="結果1" >}}
{{< bsimage src="./image/PA/IMG180101-010453-000088F.jpeg" title="結果2" >}}
{{< bsimage src="./image/PA/IMG180101-010503-000089F.jpeg" title="結果3" >}}
{{< bsimage src="./image/PA/IMG180101-010509-000090F.jpeg" title="結果4" >}}
{{< bsimage src="./image/PA/IMG180101-010514-000091F.jpeg" title="結果5" >}}

写真を見ると分かりますが、Pressure Advance が `0.000-0.025` の間だと角の外側が膨らんでしまい、`0.045` を越えると角の手前で押し出し不足が発生してしまいます。そのため、`0.030-0.040` の間に最適値があることになりますが、`0.040` は角の外側が膨らまない一方で角の内側の直角がなまってしまっています。そのため、その直前の `0.035` を Pressure Advance として採用することにしました。とはいえ、肉眼で確認したときも同じ結果でしたので、顕微鏡を取り出さないと正確な判断ができないということはなさそうです。

## まとめ

顕微鏡を使えば肉眼で確認するときより簡単に判別できるようになるかと思ったのですが、結果的に肉眼で見たときと同じ結果になりました。

そのため、顕微鏡を取り出してくる手間を考えると、肉眼＆虫眼鏡という組み合わせで確認する方法で必要十分な結果が得られるという結論が出たところで、本記事を終りたいと思います。