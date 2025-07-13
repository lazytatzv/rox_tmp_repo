# Servo Motor Device Setup

このドキュメントでは、サーボモータデバイスの安定したデバイス名を設定する方法について説明します。

## 問題

USBシリアルデバイス（サーボモータコントローラー）は、接続順序によって異なるデバイス名（`/dev/ttyACM0`, `/dev/ttyACM1`など）が割り当てられる場合があります。これにより、アプリケーションが正しいデバイスに接続できなくなる可能性があります。

## 解決策

udevルールを使用して、サーボモータデバイスに安定したシンボリックリンク `/dev/servo` を作成します。

## セットアップ手順

### 1. 自動セットアップ（推奨）

プロジェクトルートディレクトリで以下のスクリプトを実行します：

```bash
./scripts/setup_servo_udev.sh
```

このスクリプトは以下を実行します：
- 接続されているUSBシリアルデバイスを特定
- デバイスの詳細情報を表示
- udevルールをインストール
- インストールをテスト

### 2. 手動セットアップ

#### 2.1 デバイス情報の確認

サーボモータデバイスを接続し、以下のコマンドでデバイス情報を確認します：

```bash
# 接続されているttyACMデバイスを確認
ls -la /dev/ttyACM*

# デバイスの詳細情報を取得
udevadm info -a -n /dev/ttyACM0 | grep -E "idVendor|idProduct|serial"

# または
lsusb -v | grep -A 10 -B 10 "ttyACM"
```

#### 2.2 udevルールのインストール

```bash
# udevルールファイルをシステムディレクトリにコピー
sudo cp 99-servo-motor.rules /etc/udev/rules.d/

# udevルールを再読み込み
sudo udevadm control --reload-rules
sudo udevadm trigger
```

#### 2.3 動作確認

```bash
# サーボデバイスのシンボリックリンクを確認
ls -la /dev/servo*

# デバイスが見つからない場合は、デバイスを再接続
```

## udevルールのカスタマイズ

デフォルトのudevルールが動作しない場合は、`99-servo-motor.rules`ファイルを編集して、お使いのデバイスに合わせてカスタマイズしてください。

### よくあるデバイスタイプ

1. **Arduino Uno/Nano**: `idVendor="2341", idProduct="0043"`
2. **CH340 USB-Serial**: `idVendor="1a86", idProduct="7523"`
3. **FTDI USB-Serial**: `idVendor="0403", idProduct="6001"`
4. **CP210x USB-Serial**: `idVendor="10c4", idProduct="ea60"`

### カスタムルールの例

特定のシリアル番号を持つデバイス用：

```bash
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", ATTRS{serial}=="YOUR_SERIAL_NUMBER", SYMLINK+="servo"
```

複数のサーボコントローラー用：

```bash
SUBSYSTEM=="tty", ATTRS{serial}=="SERVO1_SERIAL", SYMLINK+="servo1"
SUBSYSTEM=="tty", ATTRS{serial}=="SERVO2_SERIAL", SYMLINK+="servo2"
```

## トラブルシューティング

### シンボリックリンクが作成されない

1. デバイスの接続を確認
2. `dmesg | tail` でカーネルログを確認
3. `udevadm info -a -n /dev/ttyACM0` でデバイス属性を再確認
4. udevルールファイルの構文を確認

### 権限エラー

1. ユーザーが`dialout`グループに属していることを確認：
   ```bash
   sudo usermod -a -G dialout $USER
   # 再ログインまたは再起動が必要
   ```

2. デバイスの権限を確認：
   ```bash
   ls -la /dev/servo
   ```

### Dockerでの使用

Docker環境では、以下の設定が必要です：

```yaml
services:
  ros2_rox:
    devices:
      - /dev/servo:/dev/servo
    # または全てのデバイスをマウント
    # - /dev/*:/dev/*
```

## 設定ファイルの更新

udevルールの設定後、以下のファイルが自動的に更新されています：

- `ros_ws/config/mecanum.yaml`: `serial_port: "/dev/servo"`
- `resources/serial_reader.py`: `SERIAL_PORT = "/dev/servo"`
- `resources/send_command_with_crc.cpp`: `/dev/servo`を使用
- `ros_ws/src/mecanum_wheel_controller/src/mecanum_wheel_controller_node.cpp`: デフォルトパラメータを`/dev/servo`に変更

これにより、USBデバイスの接続順序に関係なく、常に正しいサーボモータデバイスに接続できるようになります。