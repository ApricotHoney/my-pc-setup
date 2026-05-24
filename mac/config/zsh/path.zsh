# 2026年5月版: Apple Silicon mac の PATH 整理 (~/.zshrc から source される想定)
#
# 既存 .zshrc に各種ツール (Volta / Conda / Windsurf / Kiro 等) が独自に PATH を
# 追加するため、それらと競合せず・順序を維持できるようにここで一括定義する。
#
# 順序の方針 (前にあるほど優先):
#   1. /opt/homebrew/bin … Apple Silicon Homebrew (システム /usr/bin より優先)
#   2. ~/.local/bin       … uv tool / pipx 等のユーザ CLI
#   3. mise shims         … 各言語ランタイム
#   4. Volta              … Node 専用 (mise を使うなら不要)
#   5. その他 (既存 zshrc が前置/後置で追加)
#
# 重複追加を防ぐため `typeset -U path` で zsh の path 重複排除を有効化する。

# 重複を自動排除 (PATH と path 配列を同期)
typeset -U path PATH

# --- 1. Homebrew (Apple Silicon) ---
if [[ -x /opt/homebrew/bin/brew ]]; then
  # brew shellenv は INFOPATH / MANPATH / HOMEBREW_PREFIX 等も設定
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- 2. ユーザ CLI ---
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)

# --- 3. mise (言語ランタイム) ---
# Volta と二重管理しない場合のみ有効化。両方使うと Node の解決順で迷子になる。
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# --- 4. Volta (Node) ---
# mise を Node 管理に使っているなら Volta のブロックは ~/.zshrc 側でコメントアウト推奨。
# このスクリプトは Volta を“追加”はせず、すでに ~/.zshrc が export していれば尊重する。

# --- 5. fzf キーバインド ---
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null || true
fi

# --- 6. eza (ls 置換) のエイリアス ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
  alias tree='eza --tree'
fi

# --- 7. bat (cat 置換) ---
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never --style=plain'
fi
