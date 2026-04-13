#!/usr/bin/env zsh
set -euo pipefail

# ============================================================
#  install.sh  –  TEXT+ スタイルコピーツール インストーラー
#
#  使い方:
#    ./scripts/install.sh [TARGET_FILE]
#
#  デフォルトのインストール先:
#    ~/Library/Application Support/Blackmagic Design/
#      DaVinci Resolve/Fusion/Scripts/Utility/text_style_copier/main.lua
#
#  環境変数 RESOLVE_SCRIPTS_TARGET でインストール先を上書き可能。
# ============================================================

PROJECT_ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
SRC_FILE="$PROJECT_ROOT/src/main.lua"

DEFAULT_TARGET="$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility/text_style_copier/main.lua"
TARGET_FILE="${1:-${RESOLVE_SCRIPTS_TARGET:-$DEFAULT_TARGET}}"

print_usage() {
  cat <<EOF
Usage:
  ./scripts/install.sh [TARGET_FILE]

  TARGET_FILE  : インストール先のフルパス (省略時はデフォルト)
               デフォルト: .../Scripts/Utility/text_style_copier/main.lua

環境変数:
  RESOLVE_SCRIPTS_TARGET : デフォルトのインストール先を変更
EOF
}

# オプション解析
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --*)
      echo "不明なオプション: $1" >&2
      print_usage
      exit 1
      ;;
    *)
      TARGET_FILE="$1"
      shift
      ;;
  esac
done

TARGET_DIR="$(dirname -- "$TARGET_FILE")"

# インストール先ディレクトリを作成
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ディレクトリを作成します: $TARGET_DIR"
  mkdir -p "$TARGET_DIR"
fi

# スクリプトをコピー
cp "$SRC_FILE" "$TARGET_FILE"

echo ""
echo "=========================================="
echo "  インストール完了!"
echo "  コピー先: $TARGET_FILE"
echo "=========================================="
echo ""
echo "DaVinci Resolve を開き、以下から実行できます:"
echo "  ワークスペース > スクリプト > Utility > text_style_copier > main"
echo ""
