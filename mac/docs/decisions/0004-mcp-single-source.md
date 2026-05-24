# 0004. MCP 設定は `servers.json` を真実のソースに 2 クライアントへ配る

- **Status**: Accepted
- **Date**: 2026-05-24
- **Deciders**: Daisuke Arakawa

## Context

MCP (Model Context Protocol) サーバーを **Claude Code (CLI)** と **VS Code (Copilot Chat)** の両方に登録したい。
両クライアントの設定経路は別:

| クライアント | 設定方法 | 保存先 |
|---|---|---|
| Claude Code | `claude mcp add --transport <stdio\|http> --scope user <name> -- ...` | `~/.claude.json` |
| VS Code | JSON ファイル (`mcp.json`) | `~/Library/Application Support/Code/User/mcp.json` または `.vscode/mcp.json` |

加えて将来 Cursor / Aider など別クライアントを足す可能性もある。
**それぞれを手書きすると同期がドリフトする** ことが目に見えている。

## Decision

- **真実のソース**: `config/mcp/servers.json`
- **コンバータ**: `scripts/60-mcp.sh` が `jq` で 2 種類の出力を生成
  - Claude Code: `claude mcp add` のシリーズコマンドへ展開 (既存名は一度 `remove` してから再登録 = 冪等)
  - VS Code: `~/Library/Application Support/Code/User/mcp.json` を上書き (事前 `backup_file`)
- **項目スキーマ**:
  ```json
  {
    "_doc": "なぜこの server を入れるか",
    "transport": "stdio" | "http",
    "command": "...", "args": [...],     // stdio のみ
    "url": "...", "auth_env": "PAT_VAR",  // http のみ
    "enabled": true|false
  }
  ```
- **デフォルト有効**: filesystem / fetch / git / memory / sequential-thinking / playwright
- **デフォルト無効**: github (PAT が必要なため `enabled: false`)

## Consequences

- ✅ MCP の追加は `servers.json` に 1 エントリ書くだけ → 両クライアントに同時反映
- ✅ `enabled: false` でトグル容易、検証も `--only 60` で速い
- ✅ 将来クライアントを足すときは `60-mcp.sh` に新コンバータを追加するだけ
- ❌ 完全に同じ機能セットが両クライアントに供給される (個別にカスタムしたい場合は workaround が要る)
- ❌ `jq` 依存 (ただし Brewfile に含まれるので問題なし)

## Alternatives considered

- **クライアントごとに JSON / コマンドを手書き**: 却下。1 度しか書かない前提でも、新規 MCP を足すたびに 2 箇所書く事故が起きる
- **TOML や YAML をソースにする**: 却下。`jq` 既存依存で十分。新ツール依存を増やしたくない
- **`servers.json` を VS Code 形式そのままにして、Claude Code 側に変換**: 却下。Claude Code は `claude mcp add` がオーソリティ、JSON 形式は内部表現に近いので独立 schema が読みやすい

## Follow-up

- 新クライアント (Cursor 等) を追加する場合: `60-mcp.sh` に `setup_<client>()` を足し、`servers.json` のフォーマットは変えない
- MCP プロトコルが拡張されたら schema を拡張する (例: `roots`, `elicitation` の事前定義)
