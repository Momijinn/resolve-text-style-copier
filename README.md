# resolve-text-style-copier

DaVinci Resolve 20 用 TEXT+ スタイルコピーツール。  
あるクリップの TEXT+ からスタイル（フォント・サイズ・カラー・位置など）をコピーし、指定トラック上のすべての TEXT+ に一括適用します。

## 機能

- 再生ヘッド位置の TEXT+ からスタイルを取得
- 指定トラック上の全 TEXT+ にスタイルを一括適用
- テキスト本文（`StyledText`）はコピーしない
- 適用前に確認ダイアログを表示

### コピーされるプロパティ

| カテゴリ | 内容 |
| --- | --- |
| フォント | ファミリー、スタイル、サイズ |
| 装飾 | 下線、取り消し線 |
| 間隔 | 字間、行間、ワード間隔 |
| カラー | テキスト色、アウトライン色、シャドウ色 (要素1〜8) |
| シェーディング | 各要素の有効/無効、形状、太さ、不透明度、ぼかしなど |
| 位置・変形 | Center、回転、アンカー、ピボット |
| レイアウト | 揃え、方向、レイアウトタイプ |
| 文字変形 | 文字・ワード・ライン単位の回転、オフセット、サイズ |

## 動作環境

- macOS
- DaVinci Resolve 20（無料版・Studio 両対応）

## インストール

```bash
git clone https://github.com/<user>/resolve-text-style-copier.git
cd resolve-text-style-copier
./scripts/install.sh
```

デフォルトのインストール先:

```text
~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility/text_style_copier/main.lua
```

任意の場所にインストールする場合:

```bash
./scripts/install.sh "/path/to/target/main.lua"
```

## アンインストール

```bash
./scripts/uninstall.sh
```

## 使い方

1. DaVinci Resolve を開く
2. **ワークスペース > スクリプト > Utility > text_style_copier > main** を実行
3. **ソーストラック** をドロップダウンで選択
4. コピーしたい TEXT+ クリップの上に **再生ヘッド** を移動
5. **「スタイルをコピー (再生ヘッド位置)」** ボタンを押す
6. **ターゲットトラック** をドロップダウンで選択
7. **「スタイルを適用」** ボタンを押す
8. 確認ダイアログで **「はい」** を押すと、ターゲットトラック上の全 TEXT+ にスタイルが適用される

## ファイル構成

```text
├── src/
│   └── main.lua                # メインスクリプト
├── scripts/
│   ├── install.sh              # インストーラー
│   └── uninstall.sh            # アンインストーラー
└── README.md
```

## 制限事項

- キーフレームアニメーションには非対応（フレーム 0 の値のみコピー）
- `ShadingGradient`（グラデーション）はコピー対象外（Fusion の userdata オブジェクトのため）
- TEXT+ 以外のクリップは自動でスキップされます

## ライセンス

MIT License
