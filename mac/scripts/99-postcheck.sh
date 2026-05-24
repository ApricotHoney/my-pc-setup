#!/usr/bin/env bash
# 仕上げ: インストール状況を一覧表示。失敗していても exit 0 (情報出力のみ)。

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Postcheck"

check_cmd()  { if have_cmd "$1"; then log_success "cmd  $1 ($("$1" --version 2>/dev/null | head -1))"; else log_warning "cmd  $1 NOT FOUND"; fi; }
check_app()  { if app_installed "$1"; then log_success "app  $1.app"; else log_warning "app  $1.app NOT FOUND"; fi; }
check_cask() { if cask_installed "$1" 2>/dev/null; then log_success "cask $1"; else log_warning "cask $1 NOT FOUND"; fi; }

echo
log_info "--- CLI ---"
for c in git gh brew jq fzf ripgrep fd eza bat mise uv claude; do check_cmd "$c"; done

echo
log_info "--- Apps ---"
for a in "Karabiner-Elements" "Raycast" "Vector" "cmux" "Visual Studio Code" "Cursor" "Claude"; do check_app "$a"; done

echo
log_info "--- Claude Code MCP ---"
if have_cmd claude; then
  claude mcp list 2>/dev/null || log_warning "claude mcp list 失敗"
else
  log_warning "claude が無いため省略"
fi

echo
log_info "--- VS Code MCP file ---"
MCP_FILE="$HOME/Library/Application Support/Code/User/mcp.json"
if [[ -f "$MCP_FILE" ]]; then
  log_success "$MCP_FILE"
else
  log_warning "$MCP_FILE 未生成 (VS Code を起動後、60-mcp.sh を再実行)"
fi

echo
log_success "Postcheck done"
