#!/usr/bin/env bash
# Homebrew Cask が無いアプリの直接インストール。
# 現時点 (2026-05) で対象:
#   - Vector (vector.ethanlipnik.com) … 公式が ZIP 直配布のみ
#
# 公式 DMG/ZIP が「推奨」のアプリは Cask が無くてもここで対応する。
# 逆に Cask が存在しメンテ継続中のアプリは Brewfile 側で扱う (cmux 等)。

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Non-Brew apps"

install_vector() {
  if app_installed "Vector"; then
    log_success "Vector already installed (skip). 更新は Vector 内 (Settings > Update) から。"
    return 0
  fi

  local url="https://vector.ethanlipnik.com/Vector.zip"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  log_info "Downloading Vector from $url ..."
  if ! run curl -fSL "$url" -o "$tmp/Vector.zip"; then
    log_warning "Vector のダウンロードに失敗しました。URLが変わっていないか https://vector.ethanlipnik.com/ を確認してください。"
    return 1
  fi

  log_info "Unzip..."
  run /usr/bin/unzip -q "$tmp/Vector.zip" -d "$tmp"

  local app_path
  app_path="$(/usr/bin/find "$tmp" -maxdepth 3 -name 'Vector.app' -type d -print -quit)"
  [[ -n "$app_path" ]] || { log_error "Vector.app が ZIP 内に見つかりません"; return 1; }

  log_info "Install to /Applications/Vector.app"
  run /bin/mv "$app_path" "/Applications/Vector.app"

  # ダウンロードファイルの quarantine 属性を外す (Gatekeeper 初回ダイアログを軽減)
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    xattr -dr com.apple.quarantine "/Applications/Vector.app" 2>/dev/null || true
  fi

  log_success "Vector installed"
}

install_vector || log_warning "Vector のインストールに失敗しました (続行)。"

log_success "Non-Brew apps done"
