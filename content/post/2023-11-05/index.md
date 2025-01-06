---
# type: docs 
title: 2023 11 05
date: 2023-11-05T01:16:19+09:00
featured: false
draft: true
comment: true
toc: true
reward: true
pinned: false
carousel: false
series:
categories: []
tags: []
images: []
---

## 前置き

私が作成しているウェブアプリでは Bootstrap5 を使っていますが、ウィンドウ幅の変更に伴って横並びと縦並びを切替える際にボーダーの向きを変えたいと思い、以下のページの方法を使ってレスポンシブなボーダーを実現しました。

実装自体は以下のページの方法を見ればあっさり出来ましたが、なぜこのコードで実現できるのか理解するため、コード中に出てくる変数などの調査結果を備忘録として残します。

[Responsive Border Utilities · Issue #23892 · twbs/bootstrap](https://github.com/twbs/bootstrap/issues/23892#issuecomment-378172751)

## 方法

私が実現したいボーダーは、Bootstrap5 のブレークポイントと同じウィンドウ幅・プレフィックスで切り替えられるボーダーです。を実装するにはウィンドウ幅にメディアクエリ方法は、`border-lg-bottom` のような既存のクラス (`border-bottom`) を拡張したクラスを用意するというものです。

既存のクラスの拡張は手作業でもできますが、ボーダーの方向（全方向・上下・左右・上・下・左・右の7種類）とブレークポイント（sm・md・lg・xl・xxlの5種類）の組み合わせだけでも35種類になることから、手作業で設定するのは非現実です。そのため、SASS の `@each` メソッドと Bootstrap5 が用意している変数を利用して一気に作成します。ただし、Bootstrap5 が用意している変数を利用するには Bootstrap5 をローカルにインストールする必要がありますので、以下のコマンドでインストールします。

```bash
npm install bootstrap@5.3.2
```

Bootstrap5 をローカルにインストールしたら `scss` ファイルに次のコードを追加します。

```scss
@import "bootstrap/scss/bootstrap";

@each $breakpoint in map-keys($grid-breakpoints) {
  @include media-breakpoint-up($breakpoint) {
    $infix: breakpoint-infix($breakpoint, $grid-breakpoints);

    .border#{$infix}-top {      border-top: $border-width solid; }
    .border#{$infix}-end {      border-right: $border-width solid; }
    .border#{$infix}-bottom {   border-bottom: $border-width solid; }
    .border#{$infix}-start {    border-left: $border-width solid; }

    .border#{$infix}-top-0 {    border-top: 0 !important; }
    .border#{$infix}-end-0 {    border-right: 0 !important; }
    .border#{$infix}-bottom-0 { border-bottom: 0 !important; }
    .border#{$infix}-start-0 {  border-left: 0 !important; }

    .border#{$infix}-x {
      border-left: $border-width solid $border-color ;
      border-right: $border-width solid $border-color ;
    }

    .border#{$infix}-y {
      border-top: $border-width solid $border-color ;
      border-bottom: $border-width solid $border-color ;
    }
  }
}
```

`$grid-breakpoints` 変数は以下のとおり定義されたマップ型の変数で、ブレークポイントを示すプレフィックスとブレークポイントを適用するサイズが定義されています。

```scss
// scss/_variables.scss
$grid-breakpoints: (
  xs: 0,
  sm: 576px,
  md: 768px,
  lg: 992px,
  xl: 1200px,
  xxl: 1400px
);
```

この `$grid-breakpoints` 変数の全キーを `map-keys` 関数でまとめて取得し、それを `@each` メソッドに渡して順番に取り出して `$breakpoint` 変数に格納します。これで `$grid-breakpoints` 変数に定義されている各ブレークポイントのプレフィックスが順番に処理されることとなります。

それから `$breakpoint` 変数に格納されているブレークポイントのプレフィックスを `media-breakpoint-up` ミックスインに引数として渡します。`media-breakpoint-up` ミックスインの定義は以下のとおりで、渡されたプレフィックスに応じたブレークポイントの最小幅を `min-width` に設定し、`@content` の部分に呼び出し側の `.border#{$infix}-top` から `.border#{$infix}-y` までの部分を展開します。

```scss
// scss/mixins/_breakpoints.scss
// Media of at least the minimum breakpoint width. No query for the smallest breakpoint.
// Makes the @content apply to the given breakpoint and wider.
@mixin media-breakpoint-up($name, $breakpoints: $grid-breakpoints) {
  $min: breakpoint-min($name, $breakpoints);
  @if $min {
    @media (min-width: $min) {
      @content;
    }
  } @else {
    @content;
  }
}
```

また、呼び出し側の3行目に出てくる `breakpoint-infix` 関数は、渡されたブレークポイントに `-` を追加して返す（`xs` の場合は `""` を返す）関数です。関数の定義は以下のとおりです。

```scss
// scss/mixins/_breakpoints.scss
// Returns a blank string if smallest breakpoint, otherwise returns the name with a dash in front.
// Useful for making responsive utilities.
//
//    >> breakpoint-infix(xs, (xs: 0, sm: 576px, md: 768px, lg: 992px, xl: 1200px, xxl: 1400px))
//    ""  (Returns a blank string)
//    >> breakpoint-infix(sm, (xs: 0, sm: 576px, md: 768px, lg: 992px, xl: 1200px, xxl: 1400px))
//    "-sm"
@function breakpoint-infix($name, $breakpoints: $grid-breakpoints) {
  @return if(breakpoint-min($name, $breakpoints) == null, "", "-#{$name}");
}
```
