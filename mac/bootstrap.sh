#!/usr/bin/env bash
# bootstrap.sh - 2026年5月版 macOS (Apple Silicon, macOS 26+) セットアップエントリポイント
#
# 使い方:
#   ./bootstrap.sh                  # 対話実行 (推奨)
#   ./bootstrap.sh --yes            # 全プロンプト yes
#   ./bootstrap.sh --dry-run        # 実コマンドを実行せず echo のみ
#   ./bootstrap.sh --only 30,60     # 指定ステップだけ実行 (番号 prefix で指定)
#   ./bootstrap.sh --skip 70        # 指定ステップを除外
#   ./bootstrap.sh --list           # ステップ一覧を表示
#
# 各ステップは scripts/NN-*.sh として独立。単体実行も可能。
# 既存 dotfiles 移行用の mac-setup.sh とは別物 (併用可)。

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

ONLY=""
SKIP=""
LIST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y)       export NONINTERACTIVE=1 ;;
    --dry-run|-n)   export DRY_RUN=1 ;;
    --only)         ONLY="$2"; shift ;;
    --skip)         SKIP="$2"; shift ;;
    --list)         LIST=1 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) die "未知のオプション: $1" ;;
  esac
  shift
done

STEPS=(
  "scripts/00-preflight.sh"
  "scripts/10-xcode-clt.sh"
  "scripts/20-homebrew.sh"
  "scripts/30-brewfile.sh"
  "scripts/40-non-brew-apps.sh"
  "scripts/50-shell.sh"
  "scripts/60-mcp.sh"
  "scripts/70-macos-defaults.sh"
  "scripts/99-postcheck.sh"
)

if [[ "$LIST" == "1" ]]; then
  for s in "${STEPS[@]}"; do echo "  $s"; done
  exit 0
fi

# カンマ区切りの番号prefix(00,10,...) でフィルタ
should_run() {
  local file="$1"
  local num
  num="$(basename "$file" | cut -c1-2)"

  if [[ -n "$ONLY" ]]; then
    [[ ",${ONLY}," == *",${num},"* ]] || return 1
  fi
  if [[ -n "$SKIP" ]]; then
    [[ ",${SKIP}," == *",${num},"* ]] && return 1
  fi
  return 0
}

log_step "my-pc-setup / mac bootstrap (2026年5月版)"
log_info  "DRY_RUN=${DRY_RUN:-0}  NONINTERACTIVE=${NONINTERACTIVE:-0}"
[[ -n "$ONLY" ]] && log_info "ONLY=$ONLY"
[[ -n "$SKIP" ]] && log_info "SKIP=$SKIP"

confirm "セットアップを開始しますか?" || die "中断しました"

for step in "${STEPS[@]}"; do
  if should_run "$step"; then
    bash "${SCRIPT_DIR}/${step}"
  else
    log_info "skip: $step"
  fi
done

log_success "全ステップ完了。新しいターミナルを開くか、'exec zsh' で設定を再読込してください。"
