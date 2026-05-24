# mac セットアップ (2026年5月版)

Apple Silicon Mac (macOS 26+) を会社支給 / 新調時に短時間でセットアップするためのスクリプト群。

ふたつのエントリポイントを併設:

| スクリプト | 用途 |
| --- | --- |
| **`bootstrap.sh`** (新) | ゼロからのセットアップ。Homebrew / Brewfile / Vector / cmux / zsh+Prezto / MCP / macOS defaults を一括導入。 |
| `mac-setup.sh` (既存) | 自分の GitHub dotfiles リポジトリを clone してシンボリックリンクで配置する移行用ツール。 |

> 個人メモであり、自己責任での利用を前提とします。

---

## 先に読むドキュメント

- [`../AGENTS.md`](../AGENTS.md) — リポジトリ全体の規約 (人間 / AI agent 共通)
- [`docs/onboarding.md`](./docs/onboarding.md) — このディレクトリの最短経路
- [`docs/architecture.md`](./docs/architecture.md) — 設計思想 (なぜこの構成か)
- [`docs/conventions.md`](./docs/conventions.md) — スクリプト規約
- [`docs/decisions/`](./docs/decisions/) — 採用判断の ADR (例: なぜ Vector を ZIP で入れるか)

---

## 前提

- Apple Silicon (`arm64`) の Mac
- macOS 26.0 以降 (Vector / cmux などが macOS 26 を要求するため)
- インターネット接続
- 管理者権限 (Homebrew / アプリ配置 / `defaults write` に必要)

---

## クイックスタート

```bash
# 1. このリポジトリを clone (任意の場所)
git clone https://github.com/<your-account>/my-pc-setup.git
cd my-pc-setup/mac

# 2. まず動きを確認 (副作用なし)
./bootstrap.sh --dry-run --yes

# 3. 本実行
./bootstrap.sh
```

主要オプション:

```bash
./bootstrap.sh --list           # ステップ一覧
./bootstrap.sh --only 20,30     # 指定ステップだけ実行 (番号 prefix)
./bootstrap.sh --skip 70        # 指定ステップをスキップ
./bootstrap.sh --dry-run        # 実コマンドを実行せず echo のみ
./bootstrap.sh --yes            # 全プロンプトを yes 扱い (CI 向け)
```

各 `scripts/NN-*.sh` は **単独実行・再実行可能 (冪等)**。途中で失敗してもそこから再開できます。

---

## ステップ構成

| # | スクリプト | 役割 |
|---|---|---|
| 00 | `00-preflight.sh` | Apple Silicon / macOS 26+ 検証 |
| 10 | `10-xcode-clt.sh` | Xcode Command Line Tools |
| 20 | `20-homebrew.sh` | Homebrew (`/opt/homebrew`) インストール / update |
| 30 | `30-brewfile.sh` | `Brewfile` を `brew bundle` で一括導入 |
| 40 | `40-non-brew-apps.sh` | Homebrew Cask に無いアプリ (Vector) を ZIP から導入 |
| 50 | `50-shell.sh` | Prezto セットアップ + `~/.zshrc` に PATH 整理を追記 |
| 60 | `60-mcp.sh` | Claude Code (`claude mcp add`) と VS Code (`mcp.json`) に MCP サーバーを投入 |
| 70 | `70-macos-defaults.sh` | Finder / Dock / Trackpad / Keyboard の `defaults write` |
| 99 | `99-postcheck.sh` | インストール状況の一覧表示 |

---

## ディレクトリ構成

```
mac/
├── bootstrap.sh                 # メインエントリ
├── Brewfile                     # brew bundle 対象
├── mac-setup.sh                 # dotfiles 移行 (旧スクリプト, 併存)
├── scripts/
│   ├── lib/common.sh            # ログ・冪等性ヘルパー
│   ├── 00-preflight.sh ... 99-postcheck.sh
└── config/
    ├── zsh/path.zsh             # Apple Silicon mac の PATH 整理
    └── mcp/servers.json         # MCP サーバー定義 (両クライアント共通ソース)
```

---

## 2026年5月版で採用したアプリと採用しなかったもの

### 採用 (Brewfile)

- **入力 / キーマップ**: `karabiner-elements`
- **ランチャー**: `raycast` (Vector と併用、好みで切替)
- **ターミナル**: `manaflow-ai/cmux/cmux` (AI agent multitasking 向け) + `ghostty` (cmux のエンジン本家)
- **エディタ**: `visual-studio-code`, `cursor`
- **AI**: `claude` (Desktop)
- **ランタイム管理**: `mise` (asdf 後継), `uv` (Python)
- **CLI**: `gh`, `ripgrep`, `fd`, `fzf`, `eza`, `bat`, `jq`, `yq`, `btop`, `tldr`
- **仮想化**: `orbstack` (Docker Desktop の Apple Silicon 最適化代替)
- **その他**: `slack`, `notion`, `notion-calendar`, `spark`, `discord`, `tailscale`, `cloudflare-warp`, `1password`

### Homebrew では入れず Brewfile 外で扱うもの

- **Vector** (vector.ethanlipnik.com) … 公式が ZIP 直配布のみ → `scripts/40-non-brew-apps.sh` で対応
- **Claude Code CLI** … 公式インストーラ経由 (`https://claude.com/code`) を案内

### 採用しなかったもの (理由付き)

| ツール | 状況 | 代替 |
| --- | --- | --- |
| Alfred | Raycast / Vector に置き換えで十分 | Raycast / Vector |
| Rectangle (Free) | メンテ停滞気味 (Pro は維持) | macOS の Stage Manager + Karabiner、`rectangle-pro` (任意) |
| ⌘英かな / cmd-eikana | メンテナンス停滞 | **Karabiner-Elements** の left_command / right_command への eisuu / kana 割り当てで代替 |
| Docker Desktop | Apple Silicon で重い | **OrbStack** (Brewfile に含む) |

---

## MCP セットアップの仕組み

`config/mcp/servers.json` が真実のソース。`scripts/60-mcp.sh` がそれを読んで以下を行います。

1. **Claude Code**: `claude mcp add --transport <stdio|http> --scope user <name> -- <command>` を順に実行 (既存登録は一旦 remove して再登録)
2. **VS Code (Copilot Chat)**: `~/Library/Application Support/Code/User/mcp.json` を生成 (既存は backup)

デフォルトで有効化される MCP サーバー:

- `filesystem` (`@modelcontextprotocol/server-filesystem` で `$HOME` 配下)
- `fetch` (`mcp-server-fetch` via `uvx`)
- `git` (`mcp-server-git` via `uvx`)
- `memory` (`@modelcontextprotocol/server-memory`)
- `sequential-thinking`
- `playwright` (`@playwright/mcp@latest`)

GitHub remote MCP は `enabled: false` がデフォルト。使う場合は:

```bash
export GITHUB_PAT=ghp_xxxxx
# config/mcp/servers.json の "github" を enabled: true にしてから
./bootstrap.sh --only 60
```

確認:

```bash
claude mcp list                                            # Claude Code
cat "$HOME/Library/Application Support/Code/User/mcp.json" # VS Code
```

---

## zsh + Prezto: PATH 競合対策

`~/.zshrc` には複数ツール (Volta / Conda / Windsurf / Kiro / Docker) が独自に PATH を追加しがちで、順序が崩れる原因になります。`50-shell.sh` は **既存 `~/.zshrc` を上書きせず、末尾にマーカー付きで 1 ブロックだけ追記** します:

```zsh
# >>> my-pc-setup zsh path.zsh >>>
source /Users/<you>/repo/my-pc-setup/mac/config/zsh/path.zsh
# <<< my-pc-setup zsh path.zsh <<<
```

`config/zsh/path.zsh` は:

- `typeset -U path PATH` で重複排除
- `brew shellenv` を発火させて `/opt/homebrew` を PATH の先頭に
- `mise activate zsh` (もしインストールされていれば)
- `fzf --zsh` でキーバインド
- `eza` / `bat` のエイリアス

Prezto 自体は標準フローに従い `~/.zprezto` に clone、`~/.zshrc` に `source $ZPREZTO_DIR/init.zsh` を追記。`.zprofile` などに既存ファイルがある場合はリンクを貼らず警告のみ (壊さない)。

---

## macOS defaults (`scripts/70-macos-defaults.sh`)

代表的な項目だけ抜粋:

- Finder: 隠しファイル表示 / パスバー / 詳細リスト / .DS_Store 抑制
- Dock: 自動隠す / スペース自動並べ替え無効
- Trackpad: タップでクリック (有線 + Bluetooth 両方)
- Keyboard: Press-and-Hold 無効 / KeyRepeat 高速
- スクリーンショット保存先: `~/Pictures/Screenshots`

全項目は `scripts/70-macos-defaults.sh` を直接参照してください。

---

## トラブルシュート

- **Vector が `https://vector.ethanlipnik.com/Vector.zip` から落ちてこない**
  - 公式サイトを開いて DL リンクが変わっていないか確認。`scripts/40-non-brew-apps.sh` の URL を書き換える。
- **`claude` コマンドが無い**
  - Claude Code を [公式](https://claude.com/code) からインストールしてから `./bootstrap.sh --only 60` を実行。
- **VS Code MCP file が生成されない**
  - VS Code を一度起動して `~/Library/Application Support/Code/User/` を作ってから再実行。
- **mise と Volta が両方有効になっている**
  - Node の解決で迷子になりやすい。`config/zsh/path.zsh` を編集してどちらかに寄せる。
- **Apple Silicon でない**
  - Preflight で失敗します。サポート対象外。

---

## dotfiles 移行用スクリプト (`mac-setup.sh`)

既存の自分の dotfiles リポジトリをホームへ展開したい場合は引き続き利用可能:

```bash
./mac-setup.sh <github_username> [repository_name]
```

詳細は `mac-setup.sh` 内のコメントを参照。
