#!/usr/bin/env bash
# zsh + Prezto セットアップ。既存 ~/.zshrc は壊さず、末尾に my-pc-setup の
# config/zsh/path.zsh を source する1行だけ追加する (idempotent)。
#
# - Prezto が未導入なら git clone
# - Prezto の標準シンボリックリンク (.zlogin, .zlogout, .zpreztorc, .zprofile, .zshenv, .zshrc) は
#   既存ファイルがある場合バックアップしてから貼る
# - ~/.zshrc には冪等にマーカー付きブロックを追記

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Shell: zsh + Prezto + PATH"

# brew install zsh は不要 (macOS 26+ は zsh 5.9+ 同梱)
ZSH_BIN="$(command -v zsh || true)"
[[ -n "$ZSH_BIN" ]] || die "zsh が見つかりません"

ZPREZTO_DIR="${ZDOTDIR:-$HOME}/.zprezto"

# Prezto 取得 (.git があれば導入済みとみなす)
if [[ -d "$ZPREZTO_DIR/.git" ]]; then
  log_success "Prezto already installed: $ZPREZTO_DIR"
else
  log_info "Cloning Prezto -> $ZPREZTO_DIR"
  run git clone --recursive https://github.com/sorin-ionescu/prezto.git "$ZPREZTO_DIR"
fi

# Prezto 標準のシンボリックリンク
# 安全策: 既存に「リンクでないファイル」がある場合は手出しせず警告だけ出す。
# 既存環境を壊さないため、ユーザーが必要だと判断したときだけ手で削除して再実行する設計。
link_prezto_rc() {
  local rc="$1"
  local target="${ZDOTDIR:-$HOME}/.${rc}"
  local source_file="$ZPREZTO_DIR/runcoms/${rc}"

  [[ -f "$source_file" ]] || { log_warning "missing $source_file (skip)"; return 0; }

  if [[ -L "$target" ]]; then
    return 0
  fi
  if [[ -e "$target" ]]; then
    log_warning "~/.${rc} は既存ファイル (リンクではない)。手動でバックアップ後、prezto/runcoms/${rc} を貼ってください: ln -s '$source_file' '$target'"
    return 0
  fi
  run ln -s "$source_file" "$target"
  log_info "Linked ~/.${rc} -> prezto/runcoms/${rc}"
}

# .zshrc は既存に独自追記があるためリンクで上書きしない。
# Prezto の本体は ~/.zshrc 内の `source $ZPREZTO_DIR/init.zsh` で読み込まれる。
for rc in zlogin zlogout zpreztorc zprofile zshenv; do
  link_prezto_rc "$rc"
done

# ~/.zshrc に Prezto の init.zsh 読み込みが無ければ追記
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
if [[ ! -f "$ZSHRC" ]]; then
  log_info "Create empty ~/.zshrc"
  run touch "$ZSHRC"
fi

if ! grep -q '/.zprezto/init.zsh' "$ZSHRC"; then
  log_info "~/.zshrc に Prezto init を追記"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    cat >> "$ZSHRC" <<'EOF'

# --- Prezto (added by my-pc-setup) ---
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi
EOF
  fi
fi

# config/zsh/path.zsh を source する1行を ~/.zshrc に追記 (マーカーで冪等)
ROOT="$(setup_root)"
PATH_ZSH="${ROOT}/config/zsh/path.zsh"
MARKER='# >>> my-pc-setup zsh path.zsh >>>'

if [[ ! -f "$PATH_ZSH" ]]; then
  log_warning "config/zsh/path.zsh が見つかりません: $PATH_ZSH"
elif grep -qF "$MARKER" "$ZSHRC"; then
  log_success "~/.zshrc は既に my-pc-setup の path.zsh を読み込み済み"
else
  log_info "~/.zshrc に my-pc-setup path.zsh の source を追記"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    cat >> "$ZSHRC" <<EOF

${MARKER}
# 2026年5月版: Apple Silicon mac の PATH 整理 (重複排除 + Homebrew/mise/fzf 設定)
if [[ -f "${PATH_ZSH}" ]]; then
  source "${PATH_ZSH}"
fi
# <<< my-pc-setup zsh path.zsh <<<
EOF
  fi
fi

# ログインシェル切替の案内
if [[ "${SHELL:-}" != "$ZSH_BIN" ]]; then
  log_warning "ログインシェルが zsh ではありません: ${SHELL:-unknown}"
  log_info "  chsh -s $ZSH_BIN"
fi

log_success "Shell setup done"
