# mac/ アーキテクチャ

なぜこの構成にしているか、設計の柱を 6 つに整理して残す。
将来 agent (人間 / AI) が「ここを変えていいか」を判断する材料にする。

---

## 柱 1: 冪等性 (Idempotency)

**何度走らせても結果が同じ** 状態を保証する。

実装パターン:

| 操作 | 冪等にするやり方 |
|---|---|
| パッケージ追加 | `brew bundle` (差分のみ実行) |
| アプリ配置 | `app_installed` でチェック後にダウンロード |
| シンボリックリンク | `[[ -L "$target" ]] && return 0` |
| `~/.zshrc` 追記 | マーカー (`# >>> my-pc-setup ... >>>`) + `grep -qF` |
| `defaults write` | 同じキー / 値であれば再書き込みしても no-op |
| MCP サーバー登録 | 既存があれば `claude mcp remove` → 再登録 |

> "状態を確認してから書く" を全スクリプトの基本動作にする。

---

## 柱 2: dry-run 経路 (No-surprise execution)

**実行前に副作用を見られる** ことを必須要件にする。

`scripts/lib/common.sh::run` が `DRY_RUN=1` のとき実コマンドを `[dry-run] ...` の echo に置換する。すべての副作用コマンドはこのラッパー経由で呼ぶ。

```bash
# 正しい
run brew install foo
run defaults write com.apple.finder ShowPathbar -bool true
run cp -a "$f" "${f}.backup-${ts}"

# 間違い (DRY_RUN が効かない)
brew install foo
mv "$src" "$dst"
```

CI 等で副作用を伴わず構文だけ検証したい場合:

```bash
DRY_RUN=1 NONINTERACTIVE=1 ./bootstrap.sh
```

---

## 柱 3: 既存環境を壊さない (Non-destructive overlays)

**ホームディレクトリの既存設定を尊重** する。会社支給機など、既に手作業で構成されている可能性がある PC に降ろしても安全に動くこと。

- `~/.zshrc` は **末尾追記のみ**。マーカーブロックで重複検知。
- `~/.zprofile`, `~/.zshenv` 等 Prezto の標準リンク先は、**実ファイルがあればリンクを貼らず警告のみ**。
- 上書きが避けられないファイル (`mcp.json` 等) は `backup_file` でタイムスタンプ付きバックアップ。
- Brewfile に新 cask を入れる場合も `brew bundle` の差分実行に任せ、削除は別 PR で議論。

破壊的操作 (上書き / 削除) は [`AGENTS.md §7`](../../AGENTS.md) のレビュー対象。

---

## 柱 4: 真実のソースは 1 つ (Single source of truth)

**同じ設定を複数クライアントに撒くときは、1 つの定義から変換出力する。**

代表例: MCP サーバー

```
config/mcp/servers.json   ← 真実のソース
   │
   ├─ scripts/60-mcp.sh で jq 変換
   │     └─→ claude mcp add ...                 (Claude Code: ~/.claude.json)
   │     └─→ ~/Library/Application Support/Code/User/mcp.json (VS Code)
```

利点:

- どちらか片方を手で書き換えると次回再生成で巻き戻る → ドリフトしない
- 新規 MCP サーバーは `servers.json` に追加するだけ
- `enabled: false` で一時無効化、トグル容易

将来 Cursor や Aider を加える場合も同じ `servers.json` を別フォーマットへ変換する関数を追加するだけ。

---

## 柱 5: Brewfile に入れるか入れないかの判断基準

**「公式が推奨するインストール方法」に従う。**

| パターン | Brewfile に入れるか |
|---|---|
| 公式に Homebrew Cask あり & 公式が推奨 | ✅ 入れる |
| 公式 tap あり & メンテ継続中 | ✅ 入れる (例: `manaflow-ai/cmux`) |
| 公式が DMG / ZIP 配布のみ | ❌ 入れない (`40-non-brew-apps.sh` で対応) |
| 公式が Mac App Store のみ | △ `mas` で別管理 |
| Cask あるがメンテ停滞 | ❌ 入れない (代替を検討して ADR を残す) |

理由: **公式の最短経路から外れると、アップデート / 署名 / 互換性で問題が起きやすい**。Homebrew Cask が無い理由には「自動更新を内蔵してるから」「コード署名の都合」など正当な理由があることが多い。

具体例:

- **Vector**: 公式が ZIP のみ + アプリ内自動更新あり → `40-non-brew-apps.sh` で ZIP 配置
- **cmux**: 公式が Homebrew tap を提供 → Brewfile
- **Claude Code CLI**: 公式インストーラ経由 → Brewfile 外、README で案内

---

## 柱 6: agent が読める構造 (Agent-readable layout)

**ファイル名・配置・命名から目的が分かる** こと。AI agent が履歴を辿らずに現在状態だけで作業できるようにする。

実装:

- `scripts/NN-name.sh` の **数字 prefix で実行順を明示** (00 が早い)
- `lib/common.sh` に共通関数を集約 (`log_info`, `run`, `backup_file`, `have_cmd`)
- 1 スクリプト = 1 責務 (例: `30-brewfile.sh` は `brew bundle` 専任)
- ADR (`docs/decisions/`) で **なぜ A ではなく B か** を残す
- AGENTS.md で **横断ルール** を集約

agent が違う設計判断をしたくなったときは:

1. 既存 ADR を読んで前提を理解
2. 反証または上書きを行う新 ADR を作成
3. コードを変更

逆順 (コード先 → ADR 後付け) は避ける。

---

## 関連

- [`onboarding.md`](./onboarding.md) — 最短経路
- [`conventions.md`](./conventions.md) — 規約 (命名・ヘルパー・スタイル)
- [`decisions/`](./decisions/) — 個別の判断ログ
- [`../../AGENTS.md`](../../AGENTS.md) — リポジトリ全体規約
