#!/usr/bin/env bash
# macOS の defaults write 設定を一括適用。
# 既存 README.md に挙がっていた内容を踏襲しつつ、2026年5月時点で有効なキーに整理。

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "macOS defaults"

# ---------------------------------------------
# Finder
# ---------------------------------------------
run defaults write com.apple.finder AppleShowAllFiles -bool true
run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
run defaults write com.apple.finder ShowPathbar -bool true
run defaults write com.apple.finder ShowStatusBar -bool true
run defaults write com.apple.finder ShowPreviewPane -bool true
run defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"     # 詳細リスト
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"     # 現フォルダ検索
run defaults write com.apple.finder NewWindowTarget -string "PfHm"
run defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
run defaults write com.apple.finder SidebarShowiCloudDrive -bool true
run defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

# ---------------------------------------------
# Dock
# ---------------------------------------------
run defaults write com.apple.dock autohide -bool true
run defaults write com.apple.dock mru-spaces -bool false                    # スペース自動並べ替え無効

# ---------------------------------------------
# メニューバー時計
# ---------------------------------------------
run defaults write com.apple.menuextra.clock ShowSeconds -bool true

# ---------------------------------------------
# デスクトップアイコン非表示
# ---------------------------------------------
run defaults write com.apple.finder CreateDesktop -bool false

# ---------------------------------------------
# トラックパッド (有線 + Bluetooth)
# ---------------------------------------------
run defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# ---------------------------------------------
# キーボード
# ---------------------------------------------
# 長押しでアクセント記号メニューを出さず、リピート入力に
run defaults write -g ApplePressAndHoldEnabled -bool false
# キーリピート速度を最速近くに
run defaults write -g KeyRepeat -int 2
run defaults write -g InitialKeyRepeat -int 15

# ---------------------------------------------
# スクリーンショット保存先
# ---------------------------------------------
SHOT_DIR="$HOME/Pictures/Screenshots"
run mkdir -p "$SHOT_DIR"
run defaults write com.apple.screencapture location -string "$SHOT_DIR"

# ---------------------------------------------
# 反映
# ---------------------------------------------
if [[ "${DRY_RUN:-0}" != "1" ]]; then
  killall Finder        2>/dev/null || true
  killall Dock          2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
fi

log_success "macOS defaults applied (一部はログイン再開で反映)"
