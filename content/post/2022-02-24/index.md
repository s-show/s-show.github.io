---
title: "Raspberry Pi 1台で3Dプリンタ2台を動かしつつタイムラプス動画を撮影する方法"
date: 2022-02-24T03:00:00+09:00
draft: false
toc: true
tags: [3Dプリンタ, 備忘録]
archives: 2022/02
---

{{<toc>}}

## 前置き

日本の3Dプリンタユーザーが集まっている Discord の 3D Printing Japan Comunity のメンバーの虎鉄悦夫さんが[Raspberry pi1台で複数台のKlipper搭載３Dプリンタを制御する方法（KIAUH活用版）｜虎鉄悦夫｜note](https://note.com/etsuo_note/n/n85e4243bf10c)という記事を執筆されたので、自分もやってみようと思ってみたら結構大変だったので、自分用の備忘録として作業記録を残します。

なお、今回の作業はゼロからのスタートではなく、2台の Raspberry Pi で2台の3Dプリンタ（Klipperインストール済）を制御している状態からスタートして、1台の Raspberry Pi で2台の3Dプリンタを動かしながらタイムラプス動画も撮影できるようにしました。

## TL;DL

 1. Klipper と Moonraker を一度削除してから2台分インストールする
 1. `klipper_config/printer_1/printer.cfg` と `klipper_config/printer_2/printer.cfg` を設定する
 1. タイムラプス動画撮影のためのスクリプトを clone する
 1. タイムラプス動画撮影のインストールスクリプトを2つ用意して修正する
 1. タイムラプス動画撮影のスクリプトをインストールする
 1. カメラの設定ファイルを2つ用意して編集する
 1. 動画を保存するディレクトリを2つ用意する
 1. FluiddPi で2台のプリンタを制御できるようにする


## 具体的な作業

### Klipper と Moonraker の削除

既存の Klipper と Moonraker の削除は、Kiauh を使うと簡単です。まず、`./kiauh/kiauh.sh` でプロンプトを開いて `3) [Remove]` を選択します。

```
/=======================================================\
|     ~~~~~~~~~~~~~~~~~ [ KIAUH ] ~~~~~~~~~~~~~~~~~     |
|        Klipper Installation And Update Helper         |
|     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     |
\=======================================================/
/=======================================================\
|     ~~~~~~~~~~~~~~~ [ Main Menu ] ~~~~~~~~~~~~~~~     |
|-------------------------------------------------------|
|  0) [Upload Log]     |       Klipper: Installed: 2    |
|                      |        Branch: master          |
|  1) [Install]        |                                |
|  2) [Update]         |     Moonraker: Installed: 2    |
|  3) [Remove]         |                                |
|  4) [Advanced]       |      Mainsail: Not installed!  |
|  5) [Backup]         |        Fluidd: Installed!      |
|                      | KlipperScreen: Not installed!  |
|  6) [Settings]       |  Telegram Bot: Not installed!  |
|                      |                                |
|                      |          DWC2: Not installed!  |
|  v3.1.0-93           |     Octoprint: Not installed!  |
|-------------------------------------------------------|
|                        Q) Quit                        |
\=======================================================/
Perform action: 3
```

次に `1) [Klipper]` を選択して Klipper を削除すると答えると、合わせて Moonraker も削除するか聞かれますので、はいと答えます。

```
/=======================================================\
|     ~~~~~~~~~~~~~~~~~ [ KIAUH ] ~~~~~~~~~~~~~~~~~     |
|        Klipper Installation And Update Helper         |
|     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     |
\=======================================================/
/=======================================================\
|     ~~~~~~~~~~~~~~ [ Remove Menu ] ~~~~~~~~~~~~~~     |
|-------------------------------------------------------|
|  Directories which remain untouched:                  |
|  --> Your printer configuration directory             |
|  --> ~/kiauh-backups                                  |
|  You need remove them manually if you wish so.        |
|-------------------------------------------------------|
|  Firmware:                |  Touchscreen GUI:         |
|  1) [Klipper]             |  5) [KlipperScreen]       |
|                           |                           |
|  Klipper API:             |  Other:                   |
|  2) [Moonraker]           |  6) [Duet Web Control]    |
|                           |  7) [OctoPrint]           |
|  Klipper Webinterface:    |  8) [PrettyGCode]         |
|  3) [Mainsail]            |  9) [Telegram Bot]        |
|  4) [Fluidd]              |                           |
|                           |  10) [MJPG-Streamer]      |
|                           |  11) [NGINX]              |
|-------------------------------------------------------|
|                       B) « Back                       |
\=======================================================/
Perform action: 1
```

これで既存の Klipper と Moonraker を削除できましたので、今度は必要な台数分 Klipper と Moonraker をインストールします。

### Klipper のインストール

インストール方法は、`./kiauh/kiauh.sh` でプロンプトを開いて `1) [Install]` を選択し、続いて `1) [Klipper]` を選択します。

```
/=======================================================\
|     ~~~~~~~~~~~~~~~~~ [ KIAUH ] ~~~~~~~~~~~~~~~~~     |
|        Klipper Installation And Update Helper         |
|     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     |
\=======================================================/
/=======================================================\
|     ~~~~~~~~~~~ [ Installation Menu ] ~~~~~~~~~~~     |
|-------------------------------------------------------|
|  You need this menu usually only for installing       |
|  all necessary dependencies for the various           |
|  functions on a completely fresh system.              |
|-------------------------------------------------------|
|  Firmware:                |  Touchscreen GUI:         |
|  1) [Klipper]             |  5) [KlipperScreen]       |
|                           |                           |
|  Klipper API:             |  Other:                   |
|  2) [Moonraker]           |  6) [Duet Web Control]    |
|                           |  7) [OctoPrint]           |
|  Klipper Webinterface:    |  8) [PrettyGCode]         |
|  3) [Mainsail]            |  9) [Telegram Bot]        |
|  4) [Fluidd]              |                           |
|                           |  Webcam:                  |
|                           |  10) [MJPG-Streamer]      |
|-------------------------------------------------------|
|                       B) « Back                       |
\=======================================================/
Perform action: 1
```

そうすると何台分インストールするか聞かれますので、必要な台数を回答するとその数だけ Klipper をインストールしてくれます。

### Moonraker のインストール

Moonraker のインストールも同様の手順で、上の画面で `2) [Moonraker]` を選択すると何台分インストールするか聞かれるので、必要な台数を回答します。

なお、インストールの最後に FluiddPi でアクセスするときに必要な IPアドレスが表示されますので、忘れずにメモします。

```bash
#########################################################
 2 Moonraker instances have been set up!
#########################################################

       ● Instance 1: 192.168.1.5:7125
       ● Instance 2: 192.168.1.5:7126
```

これで Klipper と Moonraker がサービスとして必要な台数分だけ起動されます。

```bash
systemctl -l | grep klipper
klipper-1.service  loaded active running   Starts klipper instance 1 on startup
klipper-2.service  loaded active running   Starts klipper instance 2 on startup

systemctl -l | grep moonraker
moonraker-1.service  loaded active running   Starts Moonraker 1 on startup
moonraker-2.service  loaded active running   Starts Moonraker 2 on startup
```

ちなみに、Klipper と Moonraker が1台分だけ起動されている場合のサービス状況は次のとおりです。

```bash
systemctl list-units --type=service | grep klipper
klipper.service     loaded active running Starts klipper on startup

systemctl list-units --type=service | grep moonraker
moonraker.service   loaded active running Starts Moonraker on startup
```

### `printer.cfg` の編集

`klipper_config/printer_1` と `klipper_config/printer_2` ができているはずなので、それぞれのディレクトリに `printer.cfg` を作成して設定します。私の場合、`klipper_config/printer_1/printer.cfg` を Prusa に、`klipper_config/printer_2/printer.cfg` を Ender 3 Pro に割り当てています。

`printer.cfg` の `[mcu]` に設定するシリアルポートについては、Raspberry Pi とプリンタを接続してからプリンタの電源を入れ、`./kiauh/kiauh.sh` を実行して `4) Advanced` -> `6) [Get MCU ID]` -> `1) USB` と進むと確認できます。

```
###### Identifying MCU ...
 ● (USB) MCU #1: /dev/serial/by-id/usb-Klipper_stm32f103xe_34FFFFFF344E313337570157-if00
 ● (USB) MCU #2: /dev/serial/by-id/usb-Prusa_Research__prusa3d.com__Original_Prusa_i3_MK3_CZPX3419X004XC43991-if00
```

ここで確認したシリアルポートを `[mcu]` に設定します。プリンタを取り違えるとホットエンドが常時加熱されたりしますので、その点は注意してください。そのほかの設定は、プリンタが1台の場合と同じです。

### `moonraker.conf` の編集

`klipper_config/printer_1` と `klipper_config/printer_2` に `moonraker.cfg` を作成して設定します。`printer.cfg` とは違い、`moonraker.conf` はプリンタが複数台になったことに伴って設定箇所が増えていますので、変更点と変更理由を説明します。

なお、`klipper_config/printer_1/moonraker.cfg` を Prusa に、`klipper_config/printer_2/moonraker.cfg` を Ender 3 Pro に割り当てています。

```diff
# printer_2/moonraker.cfg
[server]
-port: 7125
+port: 7126
```

Ender 3 Pro のアクセス先が「192.168.1.5:7126」となっていることに伴う変更です。

```diff
# printer_1/moonraker.cfg
[server]
-klippy_uds_address: /tmp/klippy_uds
+klippy_uds_address: /tmp/klippy_uds-1
```

```diff
# printer_2/moonraker.cfg
[server]
-klippy_uds_address: /tmp/klippy_uds
+klippy_uds_address: /tmp/klippy_uds-2
```

上記のインストールにより `/tmp/klippy_uds` が `/tmp/klippy_uds-1`、`/tmp/klippy_uds-2` になっていますので、それに合わせて変更しています。

```diff
# printer_1/moonraker.cfg
+[database]
+database_path: /home/pi/.moonraker_database_1
```

```diff
# printer_2/moonraker.cfg
+[database]
+database_path: /home/pi/.moonraker_database_2
```

デフォルトでは設定不要のセクションですが、上記のインストールにより設定する必要が生じています。

```diff
# printer_1/moonraker.cfg
[file_manager]
-config_path: ~/klipper_config
+config_path: ~/klipper_config/printer_1
```

```diff
# printer_2/moonraker.cfg
[file_manager]
-config_path: ~/klipper_config
+config_path: ~/klipper_config/printer_2
```

設定ファイルの保存場所が `/klipper_config/printer_1` と `/klipper_config/printer_2` に分かれたことに伴う変更です。

```diff
# printer_1/moonraker.cfg
[update_manager timelapse]
-#output_path: ~/timelapse/
+output_path: ~/timelapse/printer1
```

```diff
# printer_2/moonraker.cfg
[update_manager timelapse]
-#output_path: ~/timelapse/
+output_path: ~/timelapse/printer2
```

タイムラプス動画の保存場所をプリンタ毎に用意しています。

```diff
# printer_1/moonraker.cfg
[timelapse]
-#frame_path: /tmp/timelapse/
+frame_path: /tmp/timelapse/printer1
```

```diff
# printer_2/moonraker.cfg
[timelapse]
-#frame_path: /tmp/timelapse/
+frame_path: /tmp/timelapse/printer2
```

タイムラプス動画の撮影中の画像の保存先をプリンタ毎に分けています。保存先が同じだと、2台のカメラで撮影した画像が繋ぎ合わされた動画が作成されます。

```diff
# printer_2/moonraker.cfg
[timelapse]
-#snapshoturl: http://localhost:8080/?action=snapshot
+snapshoturl: http://192.168.1.5:8081/?action=snapshot
```

2台目のプリンタのみ設定します。2台の Webカメラを使うように設定していますが、2台目のカメラの URL がデフォルトの `http://localhost:8080/?action=snapshot` から変更されていますので、それに伴う変更です。なお、IPアドレス直打ちにしているのは、`localhost` では上手く接続できないときがあったためです。


### タイムラプス動画撮影のスクリプトをインストール

`git clone https://github.com/mainsail-crew/moonraker-timelapse.git` を実行してタイムラプス動画撮影スクリプトをインストールしますが、このスクリプトは、複数台のプリンタが接続されているケースに対応していないため、修正が必要です。

```bash
cp moonraker-timelapse/install.sh moonraker-timelapse/install_printer1.sh
cp moonraker-timelapse/install.sh moonraker-timelapse/install_printer2.sh
```

上記のコマンドでスクリプトを必要な台数分コピーしてから、Klipper と Moonraker を複数起動したことに伴うサービス名の変更に対応するための修正を行います。

```diff
-    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "klipper.service")" ]; then
+    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "klipper-1.service")" ]; then
-        sudo systemctl stop klipper
+        sudo systemctl stop klipper-1
-    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "moonraker.service")" ]; then
+    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "moonraker-1.service")" ]; then
-        sudo systemctl stop moonraker
+        sudo systemctl stop moonraker-1
- After=moonraker.service
- Wants=moonraker.service
+ After=moonraker-1.service
+ Wants=moonraker-1.service
- ExecStopPost=systemctl restart klipper
- ExecStopPost=systemctl restart moonraker
+ ExecStopPost=systemctl restart klipper-1
+ ExecStopPost=systemctl restart moonraker-1
-    sudo systemctl restart moonraker
+    sudo systemctl restart moonraker-1
-    sudo systemctl restart klipper
+    sudo systemctl restart klipper-1
```

スクリプトを修正したら、次のコマンドでスクリプトをインストールします。

```bash
bash ~/moonraker-timelapse/install_printer1.sh KLIPPER_CONFIG_DIR=/home/pi/klipper_config/printer_1/
bash ~/moonraker-timelapse/install_printer2.sh KLIPPER_CONFIG_DIR=/home/pi/klipper_config/printer_2/
```

引数に `KLIPPER_CONFIG_DIR=/home/pi/klipper_config/printer_1/` を指定しているのは、`printer.cfg` の保存場所が `klipper_config` から `klipper_config/printer_1` に変更されていることに対応するためです。

あとは、タイムラプス動画を保存する場所をカメラ毎に用意します。

```bash
mkdir timelapse/printer1
mkdir timelapse/printer2
```

### Webカメラの設定

次に Webカメラの設定を行います（この作業に一番悩みました）。

まず、FluiddPi をインストールしている場合、Webカメラは `webcamd.service` というサービスで制御されています。

```bash
systemctl list-units --type=service | grep webcam
webcamd.service     loaded active running the FluiddPI webcam daemon (based on OctoPi) with the user specified config
```

このサービスは `/etc/systemd/system/webcamd.service` から起動されており、コードは次のとおりです。

```ini
cat /etc/systemd/system/webcamd.service

[Unit]
Description=the FluiddPI webcam daemon (based on OctoPi) with the user specified config

[Service]
WorkingDirectory=/usr/local/bin
StandardOutput=append:/var/log/webcamd.log
StandardError=append:/var/log/webcamd.log
ExecStart=/usr/local/bin/webcamd
Restart=always
Type=forking
User=pi

[Install]
WantedBy=multi-user.target
```

そして、`/etc/systemd/system/webcamd.service` は `/usr/local/bin/webcamd` を実行していますが、`/usr/local/bin/webcamd` のコードを見ると、`~/klipper_config` ディレクトリにある複数の `webcam*.txt` を読み込んでいることが分かります。

```sh
# /usr/local/bin/webcamd 抜粋
config_dir="/home/pi/klipper_config"

echo "Starting up webcamDaemon..."
echo ""

cfg_files=()
#cfg_files+=/boot/fluidd.txt
if [[ -d ${config_dir} ]]; then
  cfg_files+=( `ls ${config_dir}/webcam*.txt` )
fi
```

そのため、複数台のWebカメラを制御したければ、`klipper_config/webcam1.txt`、`klipper_config/webcam2.txt` という具合に、カメラの台数分だけ設定ファイルを用意すれば良いということになります。

そこで、次のコマンドで設定ファイルをカメラの台数分用意するとともに、既存の `webcam.txt` を読み込ませないためにリネームします。

```bash
cp klipper_config/webcam.txt klipper_config/webcam1.txt
cp klipper_config/webcam.txt klipper_config/webcam2.txt
mv klipper_config/webcam.txt klipper_config/webcam.txt.backup
```

そして、`webcam1.txt` と `webcam2.txt` を設定しますが、カメラを複数台使う場合、デバイスファイル（`/dev/video*`）と映像の出力先（`-p 808*`）を指定する必要があります。

デバイスファイルは次のコマンドで確認できます。私のカメラは2台とも Logicool C270 なので `usb-046d_0825` の部分が同じですが、`video0, video1` が1台目のカメラ、`video2, video3` が2台目のカメラのデバイスファイルで、`webcam*.txt` では、`video0, video2` を指定します。

```bash
ls -la /dev/v4l/by-id
total 0
drwxr-xr-x 2 root root 120 Feb  6 06:17 .
drwxr-xr-x 4 root root  80 Feb  6 06:17 ..
lrwxrwxrwx 1 root root  12 Feb  6 06:17 usb-046d_0825_338DCAC0-video-index0 -> ../../video2
lrwxrwxrwx 1 root root  12 Feb  6 06:17 usb-046d_0825_338DCAC0-video-index1 -> ../../video3
lrwxrwxrwx 1 root root  12 Feb  6 06:17 usb-046d_0825_C0A8C1F0-video-index0 -> ../../video0
lrwxrwxrwx 1 root root  12 Feb  6 06:17 usb-046d_0825_C0A8C1F0-video-index1 -> ../../video1
```

映像の出力先は、`camera_http_options` に `-p 8080` とポート番号で指定します。

これらを踏まえて、デフォルト設定から変更した点は次のとおりです。

```diff
# webcam1.txt
-camera_usb_options="-r 640x480 -f 10"
+camera_usb_options="-r 640x480 -d /dev/video0"
-#camera_http_options="-n"
+camera_http_options="-n -p 8080"
```

```diff
# webcam2.txt
-camera_usb_options="-r 640x480 -f 10"
+camera_usb_options="-r 640x480 -d /dev/video2"
-#camera_http_options="-n"
+camera_http_options="-n -p 8081"
```

上手くいけば、次のとおり `webcamd.service` で2つのカメラが制御されるようになります。

```
systemctl status webcamd.service
● webcamd.service - the FluiddPI webcam daemon (based on OctoPi) with the user specified config
   Loaded: loaded (/etc/systemd/system/webcamd.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-02-06 06:49:48 GMT; 6h ago
  Process: 378 ExecStart=/usr/local/bin/webcamd (code=exited, status=0/SUCCESS)
    Tasks: 6 (limit: 3596)
   CGroup: /system.slice/webcamd.service
           ├─537 ./mjpg_streamer -o output_http.so -w ./www-mjpgstreamer -n -p 8080 -i input_uvc.so -r 640x480 -d /dev/v
           └─590 ./mjpg_streamer -o output_http.so -w ./www-mjpgstreamer -n -p 8081 -i input_uvc.so -r 640x480 -d /dev/v
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: Format............: JPEG
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: TV-Norm...........: DEFAULT
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: www-folder-path......: ./www-mjpgstreamer/
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: HTTP TCP port........: 8081
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: HTTP Listen Address..: (null)
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: username:password....: disabled
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: commands.............: disabled
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: starting input plugin input_uvc.so
Feb 06 06:49:47 fluiddpi mjpg_streamer[590]: MJPG-streamer [590]: starting output plugin: output_http.so (ID: 00)
Feb 06 06:49:48 fluiddpi systemd[1]: Started the FluiddPI webcam daemon (based on OctoPi) with the user specified config
lines 1-19/19 (END)
```

ここまできたら、後は FluiddPi 側の設定に移ります。

### FluiddPi の設定

まず、`http://fluiddpi.local` または `http://192.168.1.5:7125` にアクセスします。それから、右上のメニューアイコンをクリックしてから Add Printer をクリックします。

{{< bsimage src="image01.png" title="FluiddPi - Menu" >}}
{{< bsimage src="image02.png" title="FluiddPi - Add Printer" >}}

すると API URL の入力を求められますので、上記の Moonraker のインストールの最後に表示された `192.168.1.5:7126` を入力します。問題がなければ入力欄右側にある雲マークが緑色になりますので、SAVE ボタンを押して保存します。

{{< bsimage src="image03.png" title="FluiddPi - URL 入力" >}}

これで Printers にもう1台のプリンタが表示されますので、必要に応じて2台のプリンタの制御画面を切り替えて操作します。

{{< bsimage src="image04.png" title="FluiddPi - プリンタ追加後" >}}
