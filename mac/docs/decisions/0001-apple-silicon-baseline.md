# 0001. Apple Silicon + macOS 26+ をベースラインにする

- **Status**: Accepted
- **Date**: 2026-05-24
- **Deciders**: Daisuke Arakawa

## Context

セットアップの動作前提を決める必要がある。`bootstrap.sh` がサポートする最小要件で、機能採用の自由度と保守コストが変わる。

考慮:

- 会社支給機・私物ともに 2024 年以降の Mac であり、すでに Apple Silicon
- 採用したい主要アプリの最低要件
  - **Vector** (`vector.ethanlipnik.com`): Apple Silicon **必須**、macOS 26+
  - **cmux**: Apple Silicon ネイティブ Swift (Intel ビルドなし)
  - **OrbStack**: Apple Silicon 最適化前提
- Intel mac 対応を残すと `/usr/local` と `/opt/homebrew` の両分岐、Rosetta 経由判定など複雑化する

## Decision

`bootstrap.sh` の前提を次に固定する:

- アーキ: **Apple Silicon (`arm64`) のみ**
- OS: **macOS 26.0 以降**
- Homebrew: `/opt/homebrew` 固定
- 既存環境が Intel mac の場合は `00-preflight.sh` で即時 die

Intel mac サポートは行わない (古いコミットを参照するか、別ブランチを作る前提)。

## Consequences

- ✅ コードパスが 1 本になり、保守が軽い
- ✅ 最新アプリ (Vector / cmux 等) を制約なく採用可能
- ❌ 2023 年以前の Intel mac には使えない
- ❌ macOS 25 以前を使う環境では Vector などが弾かれる → preflight で警告

## Alternatives considered

- **Intel / Apple Silicon 両対応**: 却下。`/usr/local` 分岐 + Rosetta 検知 + cask の universal 確認、で複雑度が倍。個人 repo の維持コストに見合わない。
- **macOS 14+ などより緩い下限**: 却下。Vector が動かず、本構成のキーアプリの一つを失う。
