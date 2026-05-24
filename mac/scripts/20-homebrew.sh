#!/usr/bin/env bash
# Homebrew のインストール。Apple Silicon は /opt/homebrew が公式の配置。
# 既に入っている場合は brew update のみ実施。
# PATH 反映は ~/.zshrc には書かず、後段の 50-shell.sh が config/zsh/path.zsh で管理する。

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Homebrew"

BREW_PREFIX="/opt/homebrew"
BREW_BIN="${BREW_PREFIX}/bin/brew"

if [[ -x "$BREW_BIN" ]]; then
  log_success "Homebrew detected at $BREW_PREFIX"
else
  log_info "Homebrew をインストールします (/opt/homebrew)..."
  # 公式インストーラ。NONINTERACTIVE=1 で sudo を含めてプロンプトを省略する場合は環境変数で渡す。
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -x "$BREW_BIN" ]] || die "Homebrew のインストールに失敗しました。"
  log_success "Homebrew installed at $BREW_PREFIX"
fi

# 現プロセスの PATH に brew を入れて、以降のスクリプトから brew コマンドを使えるようにする
eval "$("$BREW_BIN" shellenv)"

log_info "brew update..."
run brew update

log_success "Homebrew ready: $(brew --version | head -1)"
