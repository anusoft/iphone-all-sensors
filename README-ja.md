# All Sensors - iPhoneセンサー ビューア

**すべての利用可能なiPhoneセンサー**からのリアルタイムデータを表示する包括的なiOSアプリ。美しいUIビジュアライゼーション付き。

**SwiftUI**で構築、**Xiaomi MiMo 2.5 Pro** AIアシスタントが動作。

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

[English](README.md) | [ไทย](README-th.md) | [中文](README-zh.md) | **日本語** | [한국어](README-ko.md) | [Español](README-es.md) | [Français](README-fr.md) | [Deutsch](README-de.md) | [Português](README-pt.md) | [العربية](README-ar.md)

## 機能

### サポートされるセンサー

| カテゴリ | センサー |
|----------|----------|
| **モーションとアクティビティ** | 加速度計、ジャイロスコープ、磁力計、デバイスモーション、歩数計、高度計、アクティビティ認識 |
| **位置とナビゲーション** | GPS（座標、高度、速度）、コンパス（真北/磁北） |
| **環境** | 気圧計（kPa、hPa、inHg、mbar）、近接センサー、画面輝度 |
| **システム** | バッテリー、プロセッサ、メモリ、ストレージ、熱状態 |
| **接続** | Bluetooth（スキャン、デバイス）、ネットワーク（Wi-Fi/セルラー） |
| **カメラとオーディオ** | カメラ情報、トーチ制御 |

### UI機能

- **リアルタイムデータ** - デバイスを移動するとリアルタイムで更新
- **美しいビジュアライゼーション**：円形ゲージ、3D携帯向き、コンパスダイヤル
- **権限フロー**：各センサーへのアクセスが必要な理由を説明するガイド付きUI
- **検索**：任意のセンサーを素早く検索
- **多言語**：English、ไทย、中文
- **ダークモード**サポート
- **診断ログ**でデバッグ

## 要件

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- 実機iPhone（ほとんどのセンサーは実機が必要）

## インストール

1. リポジトリをクローン：
```bash
git clone https://github.com/anusoft/iphone-all-sensors.git
cd iphone-all-sensors/iPhoneSensors
```

2. Xcodeで開く：
```bash
open iPhoneSensors.xcodeproj
```

3. iPhoneをターゲットデバイスとして選択

4. Apple IDでアプリに署名

5. ビルドして実行（`Cmd+R`）

6. iPhoneで**設定 → 一般 → VPNとデバイス管理**に移動し、開発者プロファイルを信頼

## プロジェクト構造

```
iPhoneSensors/
├── App/                    # アプリエントリポイント
├── Views/
│   ├── Dashboard/          # メインセンサーダッシュボード
│   ├── Sensors/            # 個別センサー詳細ビュー
│   └── Components/         # 再利用可能なUIコンポーネント
├── Services/               # センサーマネージャー
├── Models/                 # データモデル
└── Resources/              # アプリ設定
```

## アーキテクチャ

- **SwiftUI** - 宣言型UI
- **ObservableObject**パターンと`@EnvironmentObject`でリアクティブデータバインディング
- **CoreMotion** - モーションセンサー用
- **CoreLocation** - GPSとコンパス用
## ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細は[LICENSE](LICENSE)ファイルを参照

---

**注意**：ほとんどのセンサー（加速度計、ジャイロスコープなど）は実機でのみ動作し、シミュレーターでは動作しません。
