# 0003. Vector は Homebrew ではなく公式 ZIP で導入する

- **Status**: Accepted
- **Date**: 2026-05-24
- **Deciders**: Daisuke Arakawa

## Context

Vector (`https://vector.ethanlipnik.com/`) は元 Apple 社員 Ethan Lipnik が開発する Apple Silicon 向けランチャー。本リポジトリで採用したいアプリ。

しかし:

- 公式の配布形態は **ZIP 直配布のみ**
- Homebrew Cask は存在しない (2026-05 時点)
- 自動更新は **アプリ内蔵 (Settings > Update)** が公式案内

「公式が DMG/ZIP を推奨」かつ「自動更新を内蔵」しているケースで、無理に Homebrew で包むと:

1. 非公式 tap を作ることになるが、本リポジトリで継続メンテする責務が生じる
2. アプリ内自動更新と Homebrew の `brew upgrade` が二重で走り、バージョンずれが発生
3. 署名 / Sparkle (自動更新フレームワーク) の動作に Cask 配置が干渉する可能性

[`architecture.md` 柱 5](../architecture.md#柱-5-brewfile-に入れるか入れないかの判断基準) の方針に従い、Brewfile からは外す。

## Decision

- `scripts/40-non-brew-apps.sh` で公式 ZIP (`https://vector.ethanlipnik.com/Vector.zip`) を直接ダウンロード
- `/Applications/Vector.app` に展開
- 既存検出 (`app_installed "Vector"`) で再実行時はスキップ
- `xattr -dr com.apple.quarantine` で Gatekeeper の初回ダイアログを軽減
- アップデートは Vector 内 (Settings > Update) に委譲、本スクリプトは関与しない

## Consequences

- ✅ 公式推奨経路に沿うため、自動更新 / 署名で詰まらない
- ✅ Brewfile に未公認 tap を入れずに済む
- ❌ DL URL が変わると壊れる → `40-non-brew-apps.sh` 内に URL を書く前提で、変更時はそこを直す
- ❌ 初回ダウンロードに依存する (ネットワーク必須)。Brewfile 全体のオフライン化はできない

## Alternatives considered

- **自前で Homebrew tap を作る**: 却下。継続メンテのコスト + 自動更新と二重管理になる
- **手動インストールを README に書くだけ**: 却下。`bootstrap.sh` の "clone から一発" 思想に反する
- **インストールを諦めて Raycast のみにする**: 保留。Vector はローカル知識統合 / セマンティック検索の点で固有価値があるので採用したい

## Follow-up

- DL URL が変わった場合は `scripts/40-non-brew-apps.sh` の `url` 変数を更新するだけ
- 将来 Homebrew Cask が公式に出たら、本 ADR を Superseded にして Brewfile に移す
