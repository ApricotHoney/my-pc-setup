# 2026-05-24 — mac/ 2026年5月版 bootstrap 整備 + AGENTS.md / docs / ADR 追加

## 目的

会社支給される Apple Silicon Mac (macOS 26+) を「clone → 一発で実用環境」に持っていくセットアップを 2026年5月時点の最新構成に刷新する。
あわせて、人間 / AI agent が初見でも作業に入れるよう、gitagent 思想に沿ったドキュメント構造をリポジトリ全体に被せる。

旧 `mac-setup.sh` (dotfiles 移行用) は併存させ、新規エントリ `bootstrap.sh` を別に追加する方針。

---

## 環境前提 (実機)

- macOS 26.5 / Apple Silicon (arm64) / Homebrew 5.1.11 (/opt/homebrew)
- zsh 5.9 + Prezto
- 既存導入済み: Karabiner-Elements / Raycast / Rectangle / Vector / cmux / Claude Desktop / VS Code / Cursor
- 既存 `~/.zshrc` は Kiro / Volta / Prezto / Windsurf / Docker / Conda の独自追記あり (壊さないこと)

---

## 実装したもの

### A. リポジトリルート (横断ドキュメント)

| ファイル | 役割 |
|---|---|
| `README.md` | リポジトリ俯瞰 / clone 直後の動線テーブル (mac → raspberry-pi) |
| `AGENTS.md` | 人間 + AI agent 共通の規約集。不変条件 I1〜I6, ディレクトリ規約, スクリプト規約サマリ, Conventional Commits, レビュー対象, 既知前提 |
| `.gitignore` | `.DS_Store`, `*.backup-*`, `.env*`, `Brewfile.lock.json`, IDE 系を除外 |
| `docs/journal/README.md` | ジャーナル運用方針 |
| `docs/journal/2026-05-24-mac-bootstrap-and-agents.md` | この文書 |

### B. mac/ 実装本体

| ファイル | 役割 |
|---|---|
| `mac/bootstrap.sh` | メインエントリ。`--dry-run / --yes / --only / --skip / --list` 対応 |
| `mac/Brewfile` | 2026年5月版。`manaflow-ai/cmux` tap, OrbStack, mise, uv, Karabiner-Elements, Raycast, Claude, Cursor 等 |
| `mac/scripts/lib/common.sh` | 共通ヘルパー (`log_*`, `run`, `backup_file`, `app_installed`, `setup_root`, etc.) |
| `mac/scripts/00-preflight.sh` | Apple Silicon + macOS 26+ 検証 |
| `mac/scripts/10-xcode-clt.sh` | Xcode Command Line Tools |
| `mac/scripts/20-homebrew.sh` | Homebrew (`/opt/homebrew`) インストール + `brew update` |
| `mac/scripts/30-brewfile.sh` | `brew bundle --no-lock` |
| `mac/scripts/40-non-brew-apps.sh` | Vector を公式 ZIP からインストール (`vector.ethanlipnik.com/Vector.zip`) |
| `mac/scripts/50-shell.sh` | Prezto clone + `~/.zshrc` 末尾マーカー追記 (上書きしない) |
| `mac/scripts/60-mcp.sh` | `config/mcp/servers.json` → Claude Code (`claude mcp add`) + VS Code (`mcp.json`) |
| `mac/scripts/70-macos-defaults.sh` | Finder / Dock / Trackpad / Keyboard 設定 |
| `mac/scripts/99-postcheck.sh` | インストール状況の一覧表示 |
| `mac/config/zsh/path.zsh` | `~/.zshrc` から source される PATH 整理 (typeset -U / brew shellenv / mise activate / fzf / eza / bat) |
| `mac/config/mcp/servers.json` | MCP サーバー定義 (真実のソース)。filesystem, fetch, git, memory, sequential-thinking, playwright, github(off) |

### C. mac/docs/ (オンボーディング + 設計ドキュメント)

| ファイル | 役割 |
|---|---|
| `mac/README.md` | 既存を 2026年5月版に書き換え。docs への動線追記 |
| `mac/docs/onboarding.md` | clone 直後の最短経路 / ディレクトリの読み方 / 副作用マップ / トラブルシュート |
| `mac/docs/architecture.md` | 設計 6 本柱 (冪等性 / dry-run / 非破壊 / 単一ソース / Brewfile 判断基準 / agent 可読) |
| `mac/docs/conventions.md` | シェル骨子 / 命名 / `lib/common.sh` API 表 / 冪等パターン Cookbook / 互換性ノート / Conventional Commits |
| `mac/docs/decisions/README.md` | ADR 一覧 + テンプレート |
| `mac/docs/decisions/0001-apple-silicon-baseline.md` | Apple Silicon + macOS 26+ を前提に固定 |
| `mac/docs/decisions/0002-exclude-unmaintained-apps.md` | Alfred / Rectangle Free / cmd-eikana 除外 |
| `mac/docs/decisions/0003-vector-via-zip.md` | Vector は Homebrew ではなく公式 ZIP |
| `mac/docs/decisions/0004-mcp-single-source.md` | MCP は servers.json を 1 ソースに 2 クライアントへ配布 |
| `mac/docs/decisions/0005-zsh-prezto-non-destructive.md` | zsh + Prezto は既存 `~/.zshrc` を上書きしない |

---

## 設計上の選択 (本日決めたこと)

詳細は ADR に分けてあるが、要点をここに集約:

1. **Apple Silicon + macOS 26+ に絞る** → ADR-0001
2. **Vector は ZIP、cmux は公式 tap、Claude Code CLI は公式インストーラ** という「公式の最短経路」優先 → ADR-0003 + architecture 柱 5
3. **MCP の 1 ソース 2 出力** で Claude Code と VS Code を同時に整備 → ADR-0004
4. **既存 `~/.zshrc` 非破壊**: マーカー付き末尾追記のみ。Prezto runcoms は既存実ファイルがあればリンクを貼らず警告 → ADR-0005
5. **gitagent 思想の埋め込み**: `README → AGENTS.md → docs/onboarding.md → 実装` の単一動線、ADR で判断遡及、Conventional Commits でコミット可読化

---

## 検証

実機 (この Mac) で副作用なしの検証を全ステップ通過:

```bash
cd mac
for f in bootstrap.sh scripts/*.sh scripts/lib/*.sh; do bash -n "$f"; done   # 全 OK
DRY_RUN=1 NONINTERACTIVE=1 ./bootstrap.sh
# → Preflight / Xcode CLT / Homebrew / Brewfile / Vector(既存スキップ) /
#   Shell(既存 .zprofile 警告のみで非破壊) / MCP(jq 変換 OK) /
#   defaults(全 dry-run) / Postcheck まで通過
brew bundle list --file=Brewfile          # Brewfile パース可
```

実 install テストは未実施 (本実行は新マシン到着時)。

---

## 残作業 / TODO (新マシン受領後)

- [ ] 新マシンで `./bootstrap.sh` を本実行
- [ ] `60-mcp.sh` 実行前に Claude Code CLI を公式インストーラで入れる
- [ ] VS Code を一度起動してから `60-mcp.sh` の VS Code 側を有効化
- [ ] GitHub remote MCP を使う場合は `GITHUB_PAT` を export + `servers.json` で `github.enabled: true`
- [ ] mise と Volta が二重管理になる懸念 → 新マシンでは mise に寄せるか別 ADR を起こす
- [ ] dotfiles リポジトリの整備状況次第で `mac-setup.sh` も触る (今回は据え置き)

---

## 関連

- 規約: [`../../AGENTS.md`](../../AGENTS.md)
- mac クイックスタート: [`../../mac/README.md`](../../mac/README.md)
- mac オンボーディング: [`../../mac/docs/onboarding.md`](../../mac/docs/onboarding.md)
- mac 設計: [`../../mac/docs/architecture.md`](../../mac/docs/architecture.md)
- ADR 一覧: [`../../mac/docs/decisions/README.md`](../../mac/docs/decisions/README.md)
- 外部参照:
  - Vector: https://vector.ethanlipnik.com/
  - cmux: https://cmux.com / https://github.com/manaflow-ai/cmux
  - Claude Code MCP: https://code.claude.com/docs/en/mcp
  - VS Code MCP: https://code.visualstudio.com/docs/copilot/customization/mcp-servers
