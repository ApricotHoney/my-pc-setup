#!/usr/bin/env bash
# Brewfile に定義されたパッケージをまとめてインストールする。
# `brew bundle` は冪等で、すでに入っているものはスキップされる。

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Brewfile"

ROOT="$(setup_root)"
BREWFILE="${ROOT}/Brewfile"

[[ -f "$BREWFILE" ]] || die "Brewfile が見つかりません: $BREWFILE"
have_cmd brew     || die "brew コマンドが見つかりません。20-homebrew.sh を先に実行してください。"

log_info "brew bundle --file=$BREWFILE"
# --no-lock: 余計な Brewfile.lock.json を作らない
run brew bundle --file="$BREWFILE" --no-lock

log_success "Brewfile applied"

# brew cleanup は重い & 削除を伴うので opt-in
if [[ "${BREW_CLEANUP:-0}" == "1" ]]; then
  log_info "brew cleanup (BREW_CLEANUP=1)"
  run brew cleanup
fi
