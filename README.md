# my-pc-setup

新しい PC を「clone → 一発で実用環境」に持ち込むためのセットアップスクリプト集。

対象は **個人用 + 会社支給機** を想定。OS / ハードごとにディレクトリを切ってあり、各ディレクトリは自己完結します。

```
my-pc-setup/
├── README.md           ← いまここ
├── AGENTS.md           ← 人間 + AI agent が最初に読む「リポジトリ規約」
├── mac/                ← macOS (Apple Silicon / macOS 26+) — メインで整備中
│   ├── README.md
│   ├── bootstrap.sh
│   ├── Brewfile
│   ├── scripts/
│   ├── config/
│   └── docs/           ← オンボーディング / 設計思想 / ADR
└── raspberry-pi/       ← Raspberry Pi 系 (zsh + Prezto + dotfiles)
    ├── README.md
    └── raspi-setup.sh
```

---

## どこから読むか (clone 直後の動線)

| 目的 | 最初に読むファイル |
| --- | --- |
| **このリポジトリ全体を理解したい** | この `README.md` |
| **AI agent (Claude Code / Cursor / 人間) として作業に参加する** | [`AGENTS.md`](./AGENTS.md) |
| **新しい Mac をセットアップしたい** | [`mac/README.md`](./mac/README.md) → [`mac/docs/onboarding.md`](./mac/docs/onboarding.md) |
| **Mac 構成の設計判断を知りたい** | [`mac/docs/architecture.md`](./mac/docs/architecture.md), [`mac/docs/decisions/`](./mac/docs/decisions/) |
| **Raspberry Pi をセットアップしたい** | [`raspberry-pi/README.md`](./raspberry-pi/README.md) |
| **直近の作業履歴を追いたい** | [`docs/journal/`](./docs/journal/) (日付別の作業ログ) |

---

## 設計思想 (要約)

1. **冪等性 (idempotent)**: 何度走らせても結果が同じ。再実行で壊れない
2. **dry-run 前提**: 副作用がある変更は `DRY_RUN=1` で先に検証できる
3. **既存環境を壊さない**: `~/.zshrc` 等は上書きせずマーカー付き追記、リンク貼りは既存ファイルがあれば回避
4. **真実のソースは1つ**: 同じ設定を2クライアントに撒く場合 (MCP 等) は単一の JSON を変換出力
5. **agent が読める構造**: ルート → AGENTS.md → docs/ → 実装、の順で迷子にならない

詳細は [`AGENTS.md`](./AGENTS.md) と [`mac/docs/architecture.md`](./mac/docs/architecture.md) を参照。

---

## クイックスタート

```bash
git clone https://github.com/<your-account>/my-pc-setup.git
cd my-pc-setup

# Mac の場合
cd mac && ./bootstrap.sh --dry-run --yes   # まず動きを確認
./bootstrap.sh                              # 本実行

# Raspberry Pi の場合
cd raspberry-pi && bash raspi-setup.sh
```

---

## ライセンス / 免責

個人メモであり、自己責任で利用してください。`brew` / `defaults write` / シンボリックリンク貼りなど **ホームディレクトリに副作用を伴う** 操作を含みます。必ず `--dry-run` で確認してから本実行することを推奨します。
