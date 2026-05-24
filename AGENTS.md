# AGENTS.md

このリポジトリで作業する **agent** (人間 + AI assistant) 向けの規約集。
Claude Code / Cursor / Aider / Codex 系 / Copilot Chat / 人間 — 区別なくこのドキュメントが共通の "rules of the road" になる。

新規 clone した agent は **このファイル → 該当 OS の `docs/onboarding.md` → 実装** の順で読めば作業に入れる設計。

---

## 0. リポジトリの目的 (1行)

**Apple Silicon Mac / Raspberry Pi を、clone から一発で再現可能な実用環境に持ち込む。**

それ以外の目的は持たない。複雑な抽象化や汎用フレームワーク化は意図的に避ける。

---

## 1. agent が最初に必ず確認すること

1. **作業対象の OS ディレクトリ** (`mac/` か `raspberry-pi/`) を特定する
2. その配下の `README.md` と `docs/onboarding.md` を読む
3. 変更を加える前に `--dry-run` で副作用を確認する
4. 履歴を追わず **現在のコードと docs だけで意図が分かる** 状態を維持する

---

## 2. 不変条件 (絶対に守る)

以下は agent が壊してはいけない設計上の不変条件。これを破ると "再現性のあるセットアップ" という目的が崩れる。

| # | 不変条件 | 違反例 |
|---|---|---|
| I1 | **冪等性**: 同じスクリプトを2回走らせても結果が変わらない | `>> ~/.zshrc` を毎回追記する / 既存値を確認せず `defaults write` を重ねる |
| I2 | **dry-run 経路**: 副作用のあるコマンドは `run` ヘルパー (`lib/common.sh`) 経由で叩く | `mv`, `defaults write`, `brew install` を素で書く |
| I3 | **既存ホームファイル非破壊**: `~/.zshrc`, `~/.zprofile` 等は **上書きしない**。マーカー付き追記 or バックアップ後リンク | `cat > ~/.zshrc <<EOF` で全消し |
| I4 | **真実のソースは1つ**: 同じ設定を複数クライアントに配る場合は 1 JSON を変換 (例: MCP) | Claude Code 用と VS Code 用を別々に手書き |
| I5 | **Brewfile に入れるか / 入れないかの基準**: 公式が DMG/ZIP を推奨するアプリは Brewfile に入れない | Vector を無理やり tap で入れる |
| I6 | **メンテ停止ツールは入れない**: 採用判断は `docs/decisions/` に記録 | Alfred / Rectangle (Free) / cmd-eikana を復活させる |

詳細は [`mac/docs/architecture.md`](./mac/docs/architecture.md)。

---

## 3. ディレクトリ規約

```
<os>/                       # mac / raspberry-pi など OS / ハード単位で完全分離
├── README.md               # その OS のクイックスタート
├── bootstrap.sh            # メインエントリ (mac のみ。raspberry-pi は raspi-setup.sh)
├── Brewfile                # mac のみ
├── scripts/
│   ├── lib/common.sh       # ログ・冪等性ヘルパー (各スクリプトが source する)
│   └── NN-name.sh          # 数字 prefix で実行順を明示
├── config/                 # 配布するテンプレ・設定ファイル (zsh, mcp 等)
└── docs/
    ├── onboarding.md       # 「最初に読む」資料
    ├── architecture.md     # 設計思想
    ├── conventions.md      # コーディング規約
    └── decisions/          # ADR (Architecture Decision Records)
```

OS 横断の共通モジュールは作らない (再現性 > DRY)。

---

## 4. スクリプト規約 (mac/scripts/)

詳細は [`mac/docs/conventions.md`](./mac/docs/conventions.md)。要点だけ:

- ファイル名: `NN-<purpose>.sh` (例: `30-brewfile.sh`)。`NN` は実行順
- 先頭: `set -euo pipefail` + `source lib/common.sh`
- 副作用は `run <cmd>` で包む (DRY_RUN=1 で echo 化)
- ログは `log_info / log_success / log_warning / log_error / log_step`
- ファイル書き換え前に `backup_file <path>`
- `setup_root` で `mac/` のフルパスを取得
- macOS の `/bin/bash` (3.2) で動かす想定なら `mapfile` は使わない (`while IFS= read -r`)

---

## 5. Git / コミット規約

個人用リポジトリだが、agent が PR を作りやすいよう **Conventional Commits** を採用する。

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

- **type**: `feat`, `fix`, `docs`, `chore`, `refactor`, `style`, `test`, `revert`
- **scope**: 主に対象ディレクトリ (`mac`, `mac/scripts`, `mac/docs`, `raspberry-pi`, `repo`)
- **subject**: 命令形 / 50 文字以内 / 末尾ピリオドなし / 日本語可

例:

```
feat(mac/scripts): add 60-mcp.sh for Claude Code + VS Code
fix(mac/Brewfile): replace deprecated cmd-eikana with karabiner-elements
docs(mac): add architecture.md and decisions/0001
chore(repo): add .gitignore and AGENTS.md
```

### ブランチ運用 (任意)

個人作業は `main` 直 push で OK。大きな改修や AI agent からの提案は:

```
agent/<short-topic>     # AI agent が作るブランチ
feat/<short-topic>      # 人間が作る機能ブランチ
fix/<short-topic>       # バグ修正
```

---

## 6. 変更を加えるときのチェックリスト

agent (含む AI) が変更を入れる前に通すチェック:

- [ ] **目的が `docs/decisions/` の判断に矛盾していない**
- [ ] **`./bootstrap.sh --dry-run --yes` が通る**
- [ ] **`bash -n` で全シェルがシンタックスエラー無し**
- [ ] **`brew bundle list --file=Brewfile` でパース可能** (Brewfile を触った場合)
- [ ] **新規 ADR が必要な「方針変更」を含んでいない** (含むなら `docs/decisions/000X-*.md` を追加)
- [ ] **README / onboarding.md の記述と整合**

```bash
# まとめて検証 (mac/ で実行)
for f in bootstrap.sh scripts/*.sh scripts/lib/*.sh; do bash -n "$f" || exit 1; done
DRY_RUN=1 NONINTERACTIVE=1 ./bootstrap.sh
```

---

## 7. 破壊リスクの高い操作 (要レビュー)

以下を含む変更は **必ず人間が承認**。AI agent は自動 push しない:

- `~/.zshrc`, `~/.zprofile`, `~/.zshenv` を **上書きする**変更 (マーカー付き追記なら OK)
- `defaults write` のキー追加・削除
- `/Applications/*.app` の **削除** (インストールは OK)
- Brewfile から既存 cask の削除
- `xattr -dr com.apple.quarantine` を新規エントリに追加

---

## 8. 新しい OS / ハードを足すとき

`<new-os>/` を追加する場合、最低限揃えるもの:

- `<new-os>/README.md` (クイックスタート)
- `<new-os>/docs/onboarding.md` (最短経路)
- 実行スクリプトは `bootstrap.sh` または `<os>-setup.sh` のどちらか1つに統一
- ルート `README.md` の「動線テーブル」に追加

---

## 9. 既知の前提 / 制約

- **macOS**: Apple Silicon (arm64) 限定 / macOS 26+ (Vector / cmux の最低要件)
- **Homebrew**: `/opt/homebrew` 配置 (Intel mac の `/usr/local` は非対応)
- **シェル**: zsh + Prezto。bash には移植していない
- **言語ランタイム**: `mise` 推奨。Volta との二重管理は config/zsh/path.zsh で要調整
- **MCP クライアント**: Claude Code (CLI) + VS Code (Copilot Chat)

---

## 10. 関連ドキュメント

- [README.md](./README.md) - リポジトリ俯瞰
- [mac/README.md](./mac/README.md) - mac セットアップのクイックスタート
- [mac/docs/onboarding.md](./mac/docs/onboarding.md) - 新規 agent 向け最短経路
- [mac/docs/architecture.md](./mac/docs/architecture.md) - 設計思想
- [mac/docs/conventions.md](./mac/docs/conventions.md) - スクリプト規約
- [mac/docs/decisions/](./mac/docs/decisions/) - 意思決定ログ (ADR)
- [docs/journal/](./docs/journal/) - 日付別の作業ジャーナル (近況把握用)
