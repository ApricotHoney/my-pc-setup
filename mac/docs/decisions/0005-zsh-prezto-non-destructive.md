# 0005. zsh + Prezto は既存 `~/.zshrc` を上書きせずマーカー追記する

- **Status**: Accepted
- **Date**: 2026-05-24
- **Deciders**: Daisuke Arakawa

## Context

新規 mac だけでなく、**既にカスタマイズ済みの mac** (会社支給で MDM が初期化済み、または個人が手で構成済み) でも `bootstrap.sh` を流したい。

しかし `~/.zshrc` は本リポジトリのオーナーの環境ですら既に複数の独自追記がある:

- Kiro CLI の `zshrc.pre.zsh` source
- Volta の `PATH` export
- Prezto の `source init.zsh`
- Windsurf の `PATH` 追記
- Docker CLI 補完
- Conda init ブロック

これを `bootstrap.sh` で **上書き** すれば、ユーザーの既存資産が消える / 復元できない可能性がある。
逆に何も触らなければ、本リポジトリで管理したい PATH 整理 (`/opt/homebrew` 優先 / 重複排除 / mise activate / fzf / eza / bat エイリアス) が反映できない。

## Decision

`scripts/50-shell.sh` は次の方針で動く:

1. **Prezto の clone のみ行う** (`~/.zprezto/` が無ければ git clone)
2. **`~/.zprofile`, `~/.zlogin` 等の Prezto runcoms リンク**は:
   - 既にシンボリックリンクなら何もしない
   - **実ファイルがあれば警告のみ** (上書きしない)
   - 何も無ければリンクを貼る
3. **`~/.zshrc` への追記**:
   - Prezto の `init.zsh` source が無ければ末尾追記
   - `config/zsh/path.zsh` の source 行をマーカー (`# >>> my-pc-setup zsh path.zsh >>>`) 付きで末尾追記
   - マーカーで重複検出して二重追記しない

`config/zsh/path.zsh` は `~/.zshrc` の末尾で source されるので、既存追記が `path.zsh` より「前」、`path.zsh` が「後」になる。`typeset -U path PATH` を使って重複排除し、優先順は path.zsh で決まる (`/opt/homebrew` を前置)。

## Consequences

- ✅ 既存ユーザーの追記 (Volta / Conda / Windsurf / Kiro) を尊重したまま、本リポジトリの PATH 整理を被せられる
- ✅ マーカー付きで再実行しても二重追記されない
- ✅ ロールバックは `path.zsh` の source ブロックをマーカーで grep して削除するだけ
- ❌ 既存 `~/.zshrc` 内の PATH 追加順がおかしいと、`path.zsh` がそれを覆せないケースがある (例: `path=("/bad" $path)` を後から書かれていると無効化しづらい)
- ❌ Prezto の標準リンクが貼られない場合がある → 手動対応を README に明記

## Alternatives considered

- **`~/.zshrc` を完全に管理する (上書き / シンボリックリンク化)**: 却下。dotfiles リポジトリの責務であり、本 `bootstrap.sh` (環境構築) と分離したい。dotfiles 移行は `mac-setup.sh` 側
- **`~/.zshrc.d/` のような追加ロード機構を自前で作る**: 却下。Prezto / zsh の規約から外れて、別の agent が読みにくい
- **`/etc/zshrc` に書く**: 却下。システムワイドは MDM ポリシーと衝突しやすく、ユーザー領域を侵食する

## Follow-up

- ロールバック手順を `mac/docs/onboarding.md` の「副作用マップ」に記載済み
- mise と Volta が二重管理になっている問題は別 ADR で扱う候補 (現状は path.zsh のコメントで案内)
