#!/usr/bin/env zsh
set -euo pipefail

# ============================================================
#  uninstall.sh  –  TEXT+ スタイルコピーツール アンインストーラー
#
#  使い方:
#    ./scripts/uninstall.sh [TARGET_DIR] [--force]
#
#  デフォルトのアンインストール対象:
#    ~/Library/Application Support/Blackmagic Design/
#      DaVinci Resolve/Fusion/Scripts/Utility/text_style_copier/
# ============================================================

DEFAULT_TARGET="$HOME/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility/text_style_copier"

TARGET_DIR="${RESOLVE_SCRIPTS_TARGET:-$DEFAULT_TARGET}"
FORCE=0

print_usage() {
  cat <<EOF
Usage:
  ./scripts/uninstall.sh [TARGET_DIR] [--force]

  TARGET_DIR  : 削除するフォルダのフルパス (省略時はデフォルト)
  --force     : 安全チェックをスキップして強制削除

環境変数:
  RESOLVE_SCRIPTS_TARGET : デフォルトのアンインストール対象を変更
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=1
      shift
      ;;
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
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

# フォルダが存在しない場合は何もしない
if [[ ! -e "$TARGET_DIR" ]]; then
  echo "フォルダが見つかりませんでした。アンインストール不要です:"
  echo "  $TARGET_DIR"
  exit 0
fi

# 安全チェック: フォルダ名が text_style_copier であることを確認
BASENAME="$(basename -- "$TARGET_DIR")"
if [[ $FORCE -eq 0 && "$BASENAME" != "text_style_copier" ]]; then
  echo "安全チェック: 予期しないフォルダ名です: $BASENAME" >&2
  echo "意図したフォルダなら --force を付けて実行してください" >&2
  exit 1
fi

rm -rf "$TARGET_DIR"

echo ""
echo "=========================================="
echo "  アンインストール完了!"
echo "  削除: $TARGET_DIR"
echo "=========================================="
echo ""
