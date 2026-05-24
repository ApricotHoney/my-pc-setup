# mac/ オンボーディング

このディレクトリで **最初に何をすればよいか / 何が起きるか** を 5 分で把握するための資料。
新規 clone した agent (人間 / AI) はここを起点に動くこと。

> 前段: リポジトリ全体の規約は [`../../AGENTS.md`](../../AGENTS.md) を先に読む。

---

## 1. このディレクトリは何をするか

**Apple Silicon Mac (macOS 26+) を、clone から実用環境に持っていく。**

具体的には:

- Homebrew (`/opt/homebrew`) とコマンドラインツール一式
- 厳選した GUI アプリ (Karabiner-Elements / Raycast / cmux / VS Code / Cursor / Claude Desktop など)
- Homebrew Cask に無い Vector のような ZIP 直配布アプリ
- zsh + Prezto + 重複排除済み PATH
- MCP サーバー (Claude Code CLI + VS Code Copilot Chat の両方)
- Finder / Dock / Trackpad / Keyboard の `defaults write` 設定

---

## 2. ディレクトリの読み方 (1分)

```
mac/
├── bootstrap.sh              ★ メインエントリ。これだけ叩けば全部走る
├── Brewfile                  ★ brew bundle で入れるもの一覧 (Cask 含む)
├── mac-setup.sh              既存スクリプト。自分の dotfiles を clone するだけの別ツール
├── README.md                 クイックスタート
├── scripts/
│   ├── lib/common.sh         ログ・冪等性ヘルパー (全スクリプトが source)
│   ├── 00-preflight.sh       Apple Silicon / macOS 26+ チェック
│   ├── 10-xcode-clt.sh       Xcode Command Line Tools
│   ├── 20-homebrew.sh        Homebrew インストール
│   ├── 30-brewfile.sh        brew bundle 実行
│   ├── 40-non-brew-apps.sh   Vector など ZIP 配布アプリ
│   ├── 50-shell.sh           Prezto + ~/.zshrc 末尾追記
│   ├── 60-mcp.sh             Claude Code + VS Code に MCP 投入
│   ├── 70-macos-defaults.sh  defaults write 一式
│   └── 99-postcheck.sh       インストール状況の最終確認
├── config/
│   ├── zsh/path.zsh          ~/.zshrc から source される PATH 整理
│   └── mcp/servers.json      MCP サーバー定義 (真実のソース)
└── docs/                     ★ いまここ
    ├── onboarding.md         この文書
    ├── architecture.md       設計思想
    ├── conventions.md        コーディング規約
    └── decisions/            ADR (採用判断)
```

数字 prefix (`00` → `99`) は **bootstrap.sh が回す順番**。各スクリプトは単体実行可能・冪等。

---

## 3. 最短セットアップ手順 (clone 直後)

```bash
# 1. clone してこのディレクトリへ
git clone https://github.com/<your-account>/my-pc-setup.git
cd my-pc-setup/mac

# 2. まず dry-run。副作用なしで全ステップが通ることを確認
./bootstrap.sh --dry-run --yes

# 3. 出力に WARN / ERROR が無いことを確認したら本実行
./bootstrap.sh

# 4. 新しいターミナルを開く (PATH と Prezto を再読み込み)
exec zsh
```

完了後は:

- `claude mcp list` で MCP サーバーが登録されているか確認
- VS Code を起動して `MCP: List Servers` で同じものが見えるか確認
- `which brew` が `/opt/homebrew/bin/brew` を返すか確認

---

## 4. よく使うコマンド

```bash
# ステップ一覧
./bootstrap.sh --list

# 特定ステップだけ実行
./bootstrap.sh --only 30,60

# 一部を飛ばす
./bootstrap.sh --skip 70

# 副作用なしの検証実行
./bootstrap.sh --dry-run

# 対話プロンプトをスキップ (CI / 自動化向け)
./bootstrap.sh --yes
```

環境変数:

| 変数 | 効果 |
|---|---|
| `DRY_RUN=1` | 全実コマンドを `[dry-run] ...` の echo に置換 |
| `NONINTERACTIVE=1` | `confirm` プロンプトを常に yes |
| `BREW_CLEANUP=1` | `30-brewfile.sh` の最後に `brew cleanup` を走らせる |
| `GITHUB_PAT=...` | `60-mcp.sh` で GitHub remote MCP を登録 (要 `servers.json` で `enabled: true`) |

---

## 5. 各ステップが触るもの (副作用マップ)

| ステップ | 書き込み先 | 復元方法 |
|---|---|---|
| 10 | Xcode CLT を `/Library/Developer/CommandLineTools` に展開 | `sudo rm -rf /Library/Developer/CommandLineTools` |
| 20 | `/opt/homebrew` 全体 | `/opt/homebrew/uninstall` または公式アンインストーラ |
| 30 | Homebrew formula / cask (アプリは `/Applications/`) | `brew uninstall` / `brew uninstall --cask` |
| 40 | `/Applications/Vector.app` | Vector を Trash + `~/Library/Application Support/Vector` 削除 |
| 50 | `~/.zprezto/`, `~/.zshrc` (末尾追記), `~/.zprofile` 等 (新規時のみリンク) | バックアップ `*.backup-YYYYMMDD-HHMMSS` から復元 |
| 60 | `~/.claude.json`, `~/Library/Application Support/Code/User/mcp.json` | `claude mcp remove <name>` / バックアップ復元 |
| 70 | `defaults` (Finder / Dock / Trackpad / Keyboard) | `defaults delete <domain> <key>` |

---

## 6. AI agent として作業に入る場合

1. **このファイル**を読む
2. [`../../AGENTS.md`](../../AGENTS.md) の不変条件 (I1〜I6) を確認
3. [`architecture.md`](./architecture.md) で「なぜこの設計か」を把握
4. [`decisions/`](./decisions/) で過去の採用判断を確認 (例: なぜ Alfred を外したか)
5. [`conventions.md`](./conventions.md) でスクリプト規約を確認
6. 変更を入れる前に `DRY_RUN=1 NONINTERACTIVE=1 ./bootstrap.sh` で全体が通るか検証

ADR (Architecture Decision Record) を増やすべき変更を加える場合は、`decisions/000N-<topic>.md` を新規追加して PR に含めること。

---

## 7. つまずきやすいポイント

| 症状 | 対処 |
|---|---|
| `mapfile: command not found` | macOS の `/bin/bash` (3.2) で動かしている。スクリプトは zsh ではなく `/usr/bin/env bash` で起動 (Homebrew bash があれば 5.x) |
| `Vector のダウンロードに失敗` | `vector.ethanlipnik.com` の DL URL が変わった可能性。`scripts/40-non-brew-apps.sh` の `url` を更新 |
| `claude コマンドが無い` | Claude Code を [公式](https://claude.com/code) からインストール → `./bootstrap.sh --only 60` |
| `VS Code mcp.json が出ない` | VS Code を一度起動して User ディレクトリを作ってから再実行 |
| `~/.zprofile は既存ファイル` の WARN | Prezto runcoms に切り替えるなら手動でバックアップ → `ln -s` で貼る |
| mise と Volta が両方有効 | `config/zsh/path.zsh` で `mise activate` をコメントアウトするか、`~/.zshrc` の Volta ブロックを削る |

---

## 8. このリポジトリで「やらないこと」

- **macOS の System Settings GUI でしか変更できない設定** は自動化対象外 (例: TrueTone, iCloud アカウント, Apple ID)
- **dotfiles 本体の管理** は `mac-setup.sh` か別リポジトリに分離 (`bootstrap.sh` は環境構築のみ)
- **企業の MDM が配る設定** との競合解消は責務外。MDM 優先

---

## 9. 次に読むもの

- [`architecture.md`](./architecture.md) — なぜこの構成か
- [`conventions.md`](./conventions.md) — スクリプトの書き方
- [`decisions/`](./decisions/) — 個別の採用判断ログ
