#!/usr/bin/env bash
# Apple Silicon + macOS 26+ を前提とする事前チェック。
# Vector (vector.ethanlipnik.com) が macOS 26+ / Apple Silicon を要求するため、
# この最低ラインを bootstrap 全体の前提とする。

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Preflight: 環境チェック"

is_macos        || die "macOS 専用のスクリプトです。"
is_apple_silicon || die "Apple Silicon (arm64) 専用です。Rosetta 経由ではなくネイティブ arm64 で実行してください。"

MAJOR="$(macos_major)"
if [[ -z "$MAJOR" || "$MAJOR" -lt 26 ]]; then
  log_warning "macOS バージョン: $(sw_vers -productVersion) (期待: 26+)"
  log_warning "Vector など最新版を要求するアプリは動作しない可能性があります。続行しますか?"
  confirm "続けますか?" || die "中断しました。"
else
  log_success "macOS $(sw_vers -productVersion) on $(uname -m)"
fi

# シェル
if [[ -n "${SHELL:-}" && "$SHELL" != *zsh ]]; then
  log_warning "現在のログインシェルが zsh ではありません: $SHELL"
  log_info  "後段の 50-shell.sh で zsh への切り替えを案内します。"
else
  log_success "Login shell: ${SHELL:-unknown}"
fi

log_success "Preflight OK"
