# Architecture Decision Records (ADR)

このディレクトリは「**なぜこの選択をしたか**」を時系列に残す場所。
コードや Brewfile を読むだけでは見えない判断根拠を、agent (人間 / AI) が後から辿れるようにする。

## 一覧

| # | タイトル | ステータス |
|---|---|---|
| [0001](./0001-apple-silicon-baseline.md) | Apple Silicon + macOS 26+ をベースラインにする | Accepted |
| [0002](./0002-exclude-unmaintained-apps.md) | メンテナンス停滞ツール (Alfred / Rectangle Free / cmd-eikana) を除外する | Accepted |
| [0003](./0003-vector-via-zip.md) | Vector は Homebrew ではなく公式 ZIP で導入する | Accepted |
| [0004](./0004-mcp-single-source.md) | MCP 設定は `servers.json` を真実のソースに 2 クライアントへ配る | Accepted |
| [0005](./0005-zsh-prezto-non-destructive.md) | zsh + Prezto は既存 `~/.zshrc` を上書きせずマーカー追記する | Accepted |

## 書き方

新しい判断を加えるときは `NNNN-<topic>.md` を作る。テンプレート:

```markdown
# NNNN. <タイトル>

- **Status**: Proposed / Accepted / Deprecated / Superseded by ADR-XXXX
- **Date**: YYYY-MM-DD
- **Deciders**: <name>

## Context
<何を解こうとしているか / どんな制約があるか>

## Decision
<採用した方針>

## Consequences
<良い結果 / 悪い結果 / フォローアップ TODO>

## Alternatives considered
<検討した他の選択肢と却下理由>
```

過去 ADR を覆す場合は、新しい ADR を書き、旧 ADR のステータスを `Superseded by ADR-XXXX` に更新する (削除しない)。
