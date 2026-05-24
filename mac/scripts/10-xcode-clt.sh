#!/usr/bin/env bash
# Xcode Command Line Tools のインストール (git, clang, make など)。
# Homebrew より前に必要。すでに入っていればスキップ。

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Xcode Command Line Tools"

if xcode-select -p >/dev/null 2>&1; then
  log_success "Xcode CLT: $(xcode-select -p)"
  exit 0
fi

log_info "Xcode Command Line Tools をインストールします (GUIダイアログが開きます)"
run xcode-select --install || true

# 同意するまでブロックする
log_info "インストール完了までこのプロセスは待機します..."
until xcode-select -p >/dev/null 2>&1; do
  sleep 10
done
log_success "Xcode CLT installed: $(xcode-select -p)"
