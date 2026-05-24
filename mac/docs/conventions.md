# mac/ コーディング規約

`scripts/` 配下のシェルスクリプトを書く / 読む / 修正する agent (人間 / AI) が従う規約集。

> 横断ルールは [`../../AGENTS.md`](../../AGENTS.md)、設計思想は [`architecture.md`](./architecture.md)。

---

## 1. ファイル命名

| 種類 | 命名 |
|---|---|
| 実行ステップ | `scripts/NN-<purpose>.sh` (例: `30-brewfile.sh`) |
| 共通ヘルパー | `scripts/lib/<name>.sh` (例: `lib/common.sh`) |
| 設定テンプレ | `config/<area>/<file>` (例: `config/zsh/path.zsh`, `config/mcp/servers.json`) |
| ドキュメント | `docs/<name>.md` (kebab-case) |
| ADR | `docs/decisions/NNNN-<topic>.md` (例: `0003-vector-via-zip.md`) |

実行順を示す `NN` は **00 / 10 / 20 / ... / 99** の十の位刻みで空けておく (間に挿入しやすい)。

---

## 2. シェルスクリプトの骨子

すべての `scripts/NN-*.sh` は以下のテンプレに従う:

```bash
#!/usr/bin/env bash
# <スクリプトの目的を1〜3行で>

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "<ステップ名>"

# 本体: 副作用は run で包む
run brew install foo

log_success "<ステップ名> done"
```

要点:

1. **shebang は `/usr/bin/env bash`**。`zsh` で書かない (macOS の `/bin/bash` 3.2 + Homebrew bash 5.x 両方で動くこと)
2. `set -euo pipefail` を必ず付ける
3. `SCRIPT_DIR` を絶対パスで取り、`lib/common.sh` を source
4. 副作用は `run <cmd>` でラップ (DRY_RUN 対応)
5. 終了時に `log_success` でステップ名を再掲

---

## 3. `lib/common.sh` のヘルパー一覧

| 関数 | 用途 |
|---|---|
| `log_info "msg"` | 通常情報 |
| `log_success "msg"` | 成功 |
| `log_warning "msg"` | 警告 (stderr) |
| `log_error "msg"` | エラー (stderr) |
| `log_step "msg"` | セクション見出し (改行 + シアン) |
| `die "msg"` | エラー出力して `exit 1` |
| `have_cmd <cmd>` | コマンド存在判定 (`if have_cmd brew; then ...`) |
| `run <cmd> [args...]` | 副作用ラッパー。`DRY_RUN=1` で echo 化 |
| `brew_installed <formula>` | formula が入っているか |
| `cask_installed <cask>` | cask が入っているか |
| `app_installed <Name>` | `/Applications/<Name>.app` か `~/Applications/<Name>.app` |
| `backup_file <path>` | 実ファイルなら `*.backup-YYYYMMDD-HHMMSS` を作る |
| `is_macos` / `is_apple_silicon` | OS / アーキ判定 |
| `macos_major` | `sw_vers -productVersion` の major (例: "26") |
| `confirm "prompt"` | y/N プロンプト。`NONINTERACTIVE=1` で常に yes |
| `setup_root` | `mac/` のフルパスを返す |

新しいヘルパーを足す場合は `lib/common.sh` 内にコメント付きで追加し、ここの表も更新する。

---

## 4. 冪等性パターン (Cookbook)

### 4-1. ファイル追記

```bash
MARKER='# >>> my-pc-setup foo >>>'
if grep -qF "$MARKER" "$FILE"; then
  log_success "$FILE はすでに設定済み"
else
  cat >> "$FILE" <<EOF
${MARKER}
...設定...
# <<< my-pc-setup foo <<<
EOF
fi
```

### 4-2. シンボリックリンク

```bash
if [[ -L "$target" ]]; then
  return 0                      # 既にリンク済み
elif [[ -e "$target" ]]; then
  log_warning "$target は実ファイル。手動対応してください。"
  return 0
fi
run ln -s "$source" "$target"
```

### 4-3. アプリ ZIP インストール

```bash
if app_installed "Vector"; then
  log_success "Vector already installed"
  return 0
fi
# ダウンロード → unzip → mv → xattr quarantine 解除
```

### 4-4. MCP サーバー登録 (既存があれば置換)

```bash
if claude mcp get "$name" >/dev/null 2>&1; then
  run claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
fi
run claude mcp add ...
```

---

## 5. 互換性

- **bash バージョン**: macOS デフォルトの `/bin/bash` (3.2) で動く前提のヘルパーは、現状の `bootstrap.sh` 起動経路では Homebrew bash が無くても動く必要がある。
  - 避ける: `mapfile`, `readarray`, `${var^^}`, `${var,,}`, 連想配列 (`declare -A`)
  - 使う: `while IFS= read -r line; do ... done < <(cmd)`, `tr '[:lower:]' '[:upper:]'`
- **macOS バージョン**: 26+ を前提。`defaults` キーは 26 で削除/改名されたものを使わない (`AppleShowAllFiles` などは継続有効)。

---

## 6. ロギングスタイル

- 1 行 = 1 出来事 (進捗バーや動的書き換えは使わない。CI / ログ収集を阻害する)
- 日本語可。英数記号は半角
- `log_step` はセクション境界のみ。1 スクリプトで 1〜2 回
- `log_warning` / `log_error` は stderr へ。リダイレクトしやすくする

---

## 7. エラーハンドリング

- 致命: `die "msg"` で即終了
- 部分失敗で続行: 末尾に `|| true` (ただし握りつぶしの理由をコメントで残す)
- 外部 URL 失敗: `log_warning` でユーザーに URL 再確認を促す (例: Vector の DL URL 変更)

---

## 8. Git コミット規約

[`AGENTS.md §5`](../../AGENTS.md) と同じ。Conventional Commits:

```
<type>(<scope>): <subject>
```

`scope` は `mac`, `mac/scripts`, `mac/docs`, `mac/config`, `mac/Brewfile`, `raspberry-pi`, `repo` のいずれか。

良い例:

```
feat(mac/scripts): add 80-notifications.sh for Karabiner profile
fix(mac/config): preserve Volta PATH when mise is active
docs(mac/decisions): add 0006 for OrbStack over Docker Desktop
chore(mac/Brewfile): bump cmux tap reference
```

避けたい例:

```
更新                         # type も scope も無い
WIP                          # コミットを残さない (rebase で潰す)
fix bug                      # scope と内容が無い
```

---

## 9. PR / レビュー

個人 repo でも次を最低限通す:

1. `bash -n scripts/*.sh bootstrap.sh` でシンタックスチェック
2. `DRY_RUN=1 NONINTERACTIVE=1 ./bootstrap.sh` で全フロー通す
3. `Brewfile` を触ったら `brew bundle list --file=Brewfile` でパース可能性を確認
4. 不変条件 (`AGENTS.md §2`) を破っていないか自己レビュー
5. 大きな方針変更は `docs/decisions/` に ADR を新規追加

---

## 10. テスト戦略 (現状)

シェル単体テストは導入していない。代わりに:

- **dry-run** が実テストの代わり。CI を回すなら `DRY_RUN=1 NONINTERACTIVE=1 ./bootstrap.sh` を 1 ジョブとして実行
- **postcheck** (`99-postcheck.sh`) で実機の状態を点検
- 破壊的になり得る変更は、空のテスト用ユーザーで `--only NN` 単体実行 → 復旧手順を README に書く

将来 `bats` や `shellcheck` を入れる場合は ADR を起こす。
