---
title: "RClone を使って Klipper の設定をバックアップする方法"
date: 2022-01-16T01:31:30+09:00
draft: false
---

## 前置き

Raspberry Pi に Klipper と FluiddPi をインストールして色々と設定を行っていますが、万が一の事態に備えて、RClone を使って設定ファイルをクラウドストレージに定期的にバックアップするようにしまし
た。

そこで、備忘録として実施した手順をメモします。

## 手順
{{< alert " 手順の変更などに合わせて記事を修正 (2022/04/22)" >}}


### RClone のインストール

1. ホストPCから Raspberry Pi に SSH 接続する
1. `sudo ls` を実行して root ユーザのパスワードを入力しておく
1. `curl https://rclone.org/install.sh | sudo bash`  でインストール用スクリプトをダウンロードして実行する

### RClone の設定

RClone をインストールしたら、`rclone config` を実行して設定ダイアログを起動します。

なお、ここでは過去に行った設定（ `Fuliddpi_backup` ）が表示されています。

```bash
Current remotes:

Name                 Type
====                 ====
Fluiddpi_backup      drive ← 過去に行った設定

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> n
```

`n` を選択して新しい設定を開始します。

```bash
name> test
```

設定の名前を入力します。名前は任意のものを設定します。

```bash
Option Storage.
Type of storage to configure.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value.
 1 / 1Fichier
   \ "fichier"
 2 / Alias for an existing remote
   \ "alias"
 3 / Amazon Drive
   \ "amazon cloud drive"
 4 / Amazon S3 Compliant Storage Providers including AWS, Alibaba, Ceph, Digital Ocean, Dreamhost, IBM COS, Minio, SeaweedFS, and Tencent COS
   \ "s3"
 5 / Backblaze B2
   \ "b2"
 6 / Better checksums for other remotes
   \ "hasher"
 7 / Box
   \ "box"
 8 / Cache a remote
   \ "cache"
 9 / Citrix Sharefile
   \ "sharefile"
10 / Compress a remote
   \ "compress"
11 / Dropbox
   \ "dropbox"
12 / Encrypt/Decrypt a remote
   \ "crypt"
13 / Enterprise File Fabric
   \ "filefabric"
14 / FTP Connection
   \ "ftp"
15 / Google Cloud Storage (this is not Google Drive)
   \ "google cloud storage"
16 / Google Drive
   \ "drive"
17 / Google Photos
   \ "google photos"
18 / Hadoop distributed file system
   \ "hdfs"
19 / Hubic
   \ "hubic"
20 / In memory object storage system.
   \ "memory"
21 / Jottacloud
   \ "jottacloud"
22 / Koofr
   \ "koofr"
23 / Local Disk
   \ "local"
24 / Mail.ru Cloud
   \ "mailru"
25 / Mega
   \ "mega"
26 / Microsoft Azure Blob Storage
   \ "azureblob"
27 / Microsoft OneDrive
   \ "onedrive"
28 / OpenDrive
   \ "opendrive"
29 / OpenStack Swift (Rackspace Cloud Files, Memset Memstore, OVH)
   \ "swift"
30 / Pcloud
   \ "pcloud"
31 / Put.io
   \ "putio"
32 / QingCloud Object Storage
   \ "qingstor"
33 / SSH/SFTP Connection
   \ "sftp"
34 / Sia Decentralized Cloud
   \ "sia"
35 / Sugarsync
   \ "sugarsync"
36 / Tardigrade Decentralized Cloud Storage
   \ "tardigrade"
37 / Transparently chunk/split large files
   \ "chunker"
38 / Union merges the contents of several upstream fs
   \ "union"
39 / Uptobox
   \ "uptobox"
40 / Webdav
   \ "webdav"
41 / Yandex Disk
   \ "yandex"
42 / Zoho
   \ "zoho"
43 / http Connection
   \ "http"
44 / premiumize.me
   \ "premiumizeme"
45 / seafile
   \ "seafile"
Storage> 16
```

利用するオンラインストレージを聞かれるので、利用したいものを選択します。今回は Google Drive を使うので、 `16` を選択しています。

{{< alert " RClone が対応するオンラインストレージが変更されると番号は変わります。2022年4年22月時点では、Google Drive は 17 になっています。" >}}


```bash
Option client_id.
Google Application Client Id
Setting your own is recommended.
See https://rclone.org/drive/#making-your-own-client-id for how to create your own.
If you leave this blank, it will use an internal key which is low performance.
Enter a string value. Press Enter for the default ("").
client_id>
Option client_secret.
OAuth Client Secret.
Leave blank normally.
Enter a string value. Press Enter for the default ("").
client_secret>
```

`client_id` と `client_secret` を聞かれますが、空欄でOKです。

```bash
Option scope.
Scope that rclone should use when requesting access from drive.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value.
 1 / Full access all files, excluding Application Data Folder.
   \ "drive"
 2 / Read-only access to file metadata and file contents.
   \ "drive.readonly"
   / Access to files created by rclone only.
 3 | These are visible in the drive website.
   | File authorization is revoked when the user deauthorizes the app.
   \ "drive.file"
   / Allows read and write access to the Application Data folder.
 4 | This is not visible in the drive website.
   \ "drive.appfolder"
   / Allows read-only access to file metadata but
 5 | does not allow any access to read or download file content.
   \ "drive.metadata.readonly"
scope> 1
```

どのスコープ範囲を適用するか聞かれるので、フルアクセス可能な `1` を選択します。

（書き込みオンリーの権限がないため、止むを得ずフルアクセスを選択しています。）

```bash
Option root_folder_id.
ID of the root folder.
Leave blank normally.
Fill in to access "Computers" folders (see docs), or for rclone to use
a non root folder as its starting point.
Enter a string value. Press Enter for the default ("").
root_folder_id>
```

`root_folder_id` を聞かれますが、空欄のままでOKです。

```bash
Option service_account_file.
Service Account Credentials JSON file path.
Leave blank normally.
Needed only if you want use SA instead of interactive login.
Leading `~` will be expanded in the file name as will environment variables such as `${RCLONE_CONFIG_DIR}`.
Enter a string value. Press Enter for the default ("").
service_account_file>
```

`service_account_file` について聞かれますが、こちらも空欄でOKです。

```bash
Edit advanced config?
y) Yes
n) No (default)
y/n> n
```

アドバンスト設定を行うか聞かれますので、 `n` を入力してアドバンスト設定を行わず先に進みます。

```bash
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine

y) Yes (default)
n) No
y/n> n
```

オート設定を行うか聞かれますが、SSH 接続で設定しているので `n` を選択します。

```bash
Option config_token.
For this to work, you will need rclone available on a machine that has
a web browser available.
For more help and alternate methods see: https://rclone.org/remote_setup/
Execute the following on the machine with the web browser (same rclone
version recommended):
        rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"
Then paste the result.
Enter a value.
config_token> ***
```

{{< alert " この手順は変更されていますので、2022年4月22日に修正しています。" warning >}}


ダイアログに「RClone が使える PC で以下のコードを実行して結果を貼り付けること（意訳）」と指示が表示されますので、指示に従って手元の PC で `rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"` を実行します。

すると、起動したローカルサーバの URL が表示されますので、その URL にアクセスすると Google のアクセス権限設定ページにジャンプします。

```bash
2022/04/19 13:09:19 NOTICE: Config file "/home/***/.config/rclone/rclone.conf" not found - using defaults
2022/04/19 13:09:19 NOTICE: If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth?state=hogehoge
2022/04/19 13:09:19 NOTICE: Log in and authorize rclone for access
2022/04/19 13:09:19 NOTICE: Waiting for code...
```

{{< bsimage src="Google設定画面1.png" title="使用するアカウントを選択" >}}
{{< bsimage src="Google設定画面2.png" title="アクセスを許可" >}}
{{< bsimage src="Google設定画面3.png" title="RClone で使うコードをコピー" >}}

```bash
Configure this as a Shared Drive (Team Drive)?

y) Yes
n) No (default)
y/n> n
```

今回使う Google Drive がチームで使うものか聞かれますが、私の Google Drive は個人用なので `n` を選択します。

```bash
--------------------
[test]
type = drive
scope = drive
token = {"access_token":"***",...}
team_drive =
--------------------
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> y
```

これまでの選択に基づいた設定結果が表示されますので、問題がなれば `y` を選択します。

```bash
Current remotes:

Name                 Type
====                 ====
Fluiddpi_backup      drive
test                 drive

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q>
```

設定完了後のリモートドライブの一覧が表示されます。

設定が上手くできたか確認するため、 `rclone ls Fluiddpi_backup:` を実行してリモートドライブの内容が表示されるか確認します。きちんと設定できていれば、Google Drive に保存しているファイルがリストアップされます。

```bash
pi@fluiddpiender3:~ $ rclone ls Fluiddpi_backup:
    10138 FluiddPi_Prusa/klipper_config/printer.cfg
    10138 FluiddPi_Prusa/klipper_config/printer-20220110_020804.cfg
    10152 FluiddPi_Prusa/klipper_config/printer-20220110_020020.cfg
    ...
```

続いて、Cron で定期的に実行するバックアップスクリプトを作成します。スクリプトは `~/klipper_backup.sh` としました。

なお、バックアップ先の Google Drive には、あらかじめ `FluiddPi_Ender3` という名前でディレクトリを作成しています。

```bash
#!/bin/bash
rclone copy klipper_config/ Fluiddpi_backup:FluiddPi_Ender3/klipper_config
rclone copy -L klipper_logs/ Fluiddpi_backup:FluiddPi_Ender3/klipper_logs
```

スクリプトを作成したら、 `chmod 777 ~/klipper_backup.sh` コマンドでスクリプトに実行権限を与えます。

それから `crontab -e` で Cron の設定ファイルを開き、バックアップスクリプトを実行する日時を設定します。ここでは、毎日夜中の2時15分にバックアップを実行する設定にしています。

```bash
# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
15 2 * * * /home/pi/klipper_backup.sh
```

以上で設定完了です。これで毎日同じ時間にバックアップが実行されます。