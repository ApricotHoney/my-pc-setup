#!/usr/bin/env bash
# 共通ヘルパー: 各scripts/*.sh から source して使う。
# - ログ関数 (log_info / log_success / log_warning / log_error)
# - DRY_RUN対応 (環境変数 DRY_RUN=1 で実コマンドをecho置換)
# - 冪等性チェック (have_cmd / cask_installed / brew_installed)
# - 「実行前に書き込むファイル」のバックアップヘルパー

set -euo pipefail

# このスクリプトをsourceした側のbashが set -u でも壊れないよう、未設定変数は ${VAR:-} で参照する。

if [[ -z "${COMMON_SH_SOURCED:-}" ]]; then
  COMMON_SH_SOURCED=1

  # 色 (TTYでない場合は色を出さない)
  if [[ -t 1 ]]; then
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'
    C_CYAN='\033[0;36m'
    C_RESET='\033[0m'
  else
    C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''; C_RESET=''
  fi

  log_info()    { printf "%b[INFO]%b %s\n"    "$C_BLUE"   "$C_RESET" "$*"; }
  log_success() { printf "%b[OK]%b %s\n"      "$C_GREEN"  "$C_RESET" "$*"; }
  log_warning() { printf "%b[WARN]%b %s\n"    "$C_YELLOW" "$C_RESET" "$*" >&2; }
  log_error()   { printf "%b[ERROR]%b %s\n"   "$C_RED"    "$C_RESET" "$*" >&2; }
  log_step()    { printf "\n%b==> %s%b\n"     "$C_CYAN"   "$*" "$C_RESET"; }

  die() { log_error "$*"; exit 1; }

  # コマンドの存在判定
  have_cmd() { command -v "$1" >/dev/null 2>&1; }

  # ドライランで包む: DRY_RUN=1 のときは echo のみ
  run() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      printf "%b[dry-run]%b %s\n" "$C_YELLOW" "$C_RESET" "$*"
    else
      "$@"
    fi
  }

  # brew formula / cask の冪等チェック
  brew_installed() { brew list --formula --versions "$1" >/dev/null 2>&1; }
  cask_installed() { brew list --cask --versions "$1" >/dev/null 2>&1; }

  # /Applications または ~/Applications にアプリ.appが存在するか
  app_installed() {
    local app="$1"
    [[ -d "/Applications/${app}.app" || -d "$HOME/Applications/${app}.app" ]]
  }

  # ファイルをタイムスタンプ付きでバックアップ (存在する場合のみ)
  backup_file() {
    local f="$1"
    if [[ -e "$f" && ! -L "$f" ]]; then
      local ts
      ts="$(date +%Y%m%d-%H%M%S)"
      run cp -a "$f" "${f}.backup-${ts}"
      log_info "Backed up $f -> ${f}.backup-${ts}"
    fi
  }

  # OS / アーキ判定
  is_macos()         { [[ "$(uname -s)" == "Darwin" ]]; }
  is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }

  # macOS バージョンの major番号を返す (例: "26")
  macos_major() {
    sw_vers -productVersion 2>/dev/null | cut -d. -f1
  }

  # 確認プロンプト (NONINTERACTIVE=1 で常にyes扱い)
  confirm() {
    local prompt="${1:-Proceed?} [y/N]: "
    if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
      log_info "${prompt}-> yes (NONINTERACTIVE)"
      return 0
    fi
    local reply
    read -r -p "$prompt" reply
    [[ "$reply" =~ ^[Yy]$ ]]
  }

  # このスクリプト群のルート (= mac/ ディレクトリ) を返す
  setup_root() {
    # lib/common.sh の2つ上 = mac/
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd
  }
fi
