---
# type: docs 
title: Whisper を Windows ローカルで使うための作業
date: 2023-05-28T00:41:37+09:00
featured: false
draft: false
comment: true
toc: true
tags: [備忘録,プログラミング,機械学習]
archives: 2023/05
---

## 前置き

先月、Google Colab で Whisper を動かして音声をテキストに変換してブログを書いてみるという[記事](../2023-04-11/)を投稿しました。

この方法は Google Colab で実行するので、高性能の GPU が使えて環境構築の手間がかからないというメリットがある一方で、毎回ライブラリをインストールする必要があって初期セットアップに時間がかかるというデメリットがありました。そこで、ローカル環境で Whisper を動かせば初期セットアップの時間を節約できると思い、ローカル環境で Whisper を動かせるようにしました。

Whisper を動かせるようにするまで色々と作業が必要だったため、備忘録として作業内容を記録します。

## 環境

私のPC環境は次のとおりです。

<dl>
  <dt>OS</dt>
  <dd>Windows 11 Pro 22H2</dd>
  <dt>Python</dt>
  <dd>3.10.6</dd>
  <dt>グラフィックボード</dt>
  <dd>NVIDIA GeForce RTX 3060（メモリ12GB）</dd>
  <dt>NVIDIAドライバ</dt>
  <dd>バージョン535.50（執筆時点の最新版）</dd>
</dl>

## 必要となるライブラリなど

Whisper の [Github リポジトリ](https://github.com/openai/whisper)の `README.md` では、「Whisper は Python 3.9.9 と PyTorch 1.10.1 を使ってトレーニングとテストをしているが、ソースコードは Python 3.8-3.11 と最近の PyTorch にも対応していると期待される」とあります。一方、PyTorch の最新版がサポートする Python のバージョンは 3.8-3.11 で、CUDA のバージョンは 11.7 か 11.8 です。

そのため、Python については元からインストールしている 3.10.6 を使い、PyTorch はバージョンが新しい方が使いまわしができるだろうと考えて最新版を使うことにしました。CUDA は参考にしたブログ記事では 11.7 を使っていましたので、それに倣うことにしました。

以上を踏まえてインストールしたライブラリは次のとおりです。

- Build Tools for Visual Studio2022
- CUDA Toolkit 11.7
- cuDNN (for CUDA 11.x)
- PyTorch (Stable (2.0.1))

それぞれのライブラリのインストール方法は次のとおりです。

### Build Tools for Visual Studio2022のインストール

Microsoft の[配布サイト](https://visualstudio.microsoft.com/ja/downloads/)からインストーラーをダウンロードして実行します。

インストーラーを実行すると何をインストールするか聞かれますので、「C++によるデスクトップ開発」を選択し、右側に表示されるメニューから「v143ビルドツール用C++/CLIサポート(最新)」を選択してインストールします。私の環境では、最初のインストールは失敗に終わりましたが、インストール済みの古い C++ の再配布パッケージをアンインストールして再度インストールを実行したら無事にインストールできました。

{{< bsimage src="install_build_tools_visual_studio.png" title="インストールするパッケージの選択" >}}

### CUDA Toolkit 11.7

NVIDIA の[公式サイト](https://developer.nvidia.com/cuda-11-7-0-download-archive)からインストーラーをダウンロードして実行します。

実行するとインストールオプションで「高速（推奨）」と「カスタム（詳細）」を選択するよう求められます。

{{< bsimage src="cuda_tool_select_install_option.png" title="インストールオプションの選択" >}}

基本的には「高速（推奨）」を選べばよいと思うのですが、私の場合 nvidia nsight visual studio edition のインストールが失敗して全体のインストールも失敗しましたので、「カスタム（詳細）」を選択して nvidia nsight visual studio edition をインストール対象から除外してインストールしました。ちなみに、nvidia nsight visual studio edition は、Visual studio で GPU コンピューティングを開発する際にデバッグ等の機能を提供するツールのようです。

{{< bsimage src="cuda_tool_without_nsight_vse.png" title="nvidia nsight visual studio edition" >}}

インストールが終わったら CUDA Toolkit 11.7 へのパスが通っているか確認します。Windows の設定画面を開いて左上の検索ボックスに「環境変数」と入力してから「システム環境変数」を選択し、出てきた画面の下側にある「環境変数」ボタンをクリックして設定画面を開きます。そして、システム環境変数の `path` に `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.7\bin` と `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.7\libnvvp` が設定されているか確認します。

{{< bsimage src="setting_window.png" title="" >}}
{{< bsimage src="select_system_enviroment_path.png" title="" >}}
{{< bsimage src="view_system_enviroment_path.png" title="" >}}

ここでパスが通っていることを確認したら、追加の確認として、コマンドプロンプトか PowerShell を開いて `nvcc -V` コマンドを実行します。インストールに成功してパスが通っていれば、次のような結果が表示されます。

```
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2022 NVIDIA Corporation
Built on Tue_May__3_19:00:59_Pacific_Daylight_Time_2022
Cuda compilation tools, release 11.7, V11.7.64
Build cuda_11.7.r11.7/compiler.31294372_0
```

### cuDNN

cuDNN は「The NVIDIA CUDA® Deep Neural Network library」の略で、GPU を使ったディープニューラルネットワークのためのライブラリです。[公式サイト](https://developer.nvidia.com/rdp/cudnn-download)にアクセスしてインストーラーをダウンロードしますが、ダウンロードするには NVIDIA Developer に登録する必要があります。色々聞かれますので必須事項を1つ1つ答えて登録します。登録が完了したらインストーラーをダウンロードしますが、上記の作業で CUDA Toolkit 11.7をインストールしていますので、「CUDA 12.x」ではなく「CUDA 11.x」を選択します。

{{< bsimage src="download_cudnn.png" title="cuDNNのダウンロード" >}}

インストーラー（ZIPファイル）をダウンロードしたら、ダウンロードした ZIP ファイルを解凍するか Explorer で開きます。ZIPファイルには `bin` `include` `lib` フォルダが入っていますので、これらのフォルダを先程 CUDA をインストールしたフォルダ（例えば、`C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.7\`）の中にコピーします。

それから cuDNN へのパスを通します。こちらは CUDA Toolkit 11.7 とは違い自動的にパスが設定されませんので、先程と同様の手順でシステム環境変数の設定画面を開き、`CUDA_PATH` と同じ値を `CUDNN_PATH` として設定します。

### Python の仮想環境を構築

やっと PyTorch をインストールしますが、システム全体にインストールすると今後思わぬところで依存関係のトラブルが起きそうな気がしましたので、Whisper 専用の仮想環境を用意してそこにインストールすることにしました。

仮想環境は venv を使って `D:\voice2text_with_whisper_fp16` に用意することにしましたので、PowerShell を開いてこのディレクトリに移動した後 `python -m venv .venv` コマンドを実行して仮想環境を作成し、`.venv\Scripts\activate.ps1` コマンドを実行して仮想環境に切り替えました。

### PyTorch のインストール

[公式サイト](https://pytorch.org/get-started/locally/)で PyTorch のバージョンや OS の種類などを選択することで表示されるインストールコマンド (`pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117`) コマンドを実行して PyTorch をインストールします。

{{< bsimage src="generate_pytorch_install_command.png" title="PyTorchのインストールコマンド生成" >}}

### Whisper のインストール

ようやく下準備ができましたので、本命の Whisper をインストールします。[公式リポジトリ](https://github.com/openai/whisper)に掲載されている `pip install git+https://github.com/openai/whisper.git` コマンドを実行してインストールします。

## 音声ファイルの変換

これで必要な準備はできたはずですので、以下のコードを適当なファイル名 (`voice2text.py`) で保存してから、PowerShell を開いて `python3 voice2text.py "音声ファイルへのパス"` コマンドを実行して音声をテキストに変換します。 

コードは[Whisper + GPT-3 で会議音声からの議事録書き出し&サマリ自動生成をやってみる！ - Qiita](https://qiita.com/sakasegawa/items/3855472a8566ea302a99)を参考にしています。

```python
# 変換したテキストの保存場所とファイル名指定のためにインポート
import datetime
import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '.venv\lib\site-packages'))

# 入力音声の変換に必要なライブラリのインポート
import librosa
import soundfile as sf
import whisper

# 下準備
voiceFile = sys.argv[1]
def generate_transcribe(file_path):
    # Whisper高速化テクニック
    # https://qiita.com/halhorn/items/d2672eee452ba5eb6241
    model = whisper.load_model("large", device="cpu")
    _ = model.half()
    _ = model.cuda()

    # exception without following code
    # reason : model.py -> line 31 -> super().forward(x.float()).type(x.dtype)
    for m in model.modules():
        if isinstance(m, whisper.model.LayerNorm):
            m.float()
    result = model.transcribe(file_path)
    return result

# 音声ファイルのサンプリング
y, sr = librosa.load(voiceFile)
y_16k = librosa.resample(y, orig_sr=sr, target_sr=16000)
n_samples = int(15 * 60 * 16000)

# 音声ファイルを15分ごとに分割する
segments = [y_16k[i:i+n_samples] for i in range(0, len(y_16k), n_samples)]

# 分割した音声ファイルを保存する
for i, segment in enumerate(segments):
    sf.write(f"./splited_voice_file_{i}.wav", segment, 16000, format="WAV")

# 分割した音声ファイルを順番にテキストに変換
transcript = ""
for i in range(len(segments)):
    # print(fc.selected_path)
    file_path = f"./splited_voice_file_{i}.wav"
    transcribe = generate_transcribe(file_path)
    for seg in transcribe['segments']:
        transcript += seg['text'] + "\n"

# 変換したテキストをこのスクリプトと同じディレクトリに保存。
# ファイル名は日付 + 時間
now = datetime.datetime.now()
filename = now.strftime('%Y%m%d_%H%M')
f = open(filename + '.txt', 'w')
f.write(transcript)
f.close()
```

ちなみに、音声は Microsoft Store からインストールした [Windows ボイスレコーダー](https://www.microsoft.com/store/productId/9WZDNCRFHWKN)で録音しています。

## 参考にした記事等

- [Whisper + GPT-3 で会議音声からの議事録書き出し&サマリ自動生成をやってみる！ - Qiita](https://qiita.com/sakasegawa/items/3855472a8566ea302a99)
- [OpenAIのWhisperをWindows環境で試す(CUDA環境有り)](https://zenn.dev/en129/articles/ddfb3da6d0fd31)
- [WindowsへのNVIDIA CUDAのGPU環境構築 | 鷹の目週末プログラマー](https://happy-shibusawake.com/nvidia-cuda/1358/)
