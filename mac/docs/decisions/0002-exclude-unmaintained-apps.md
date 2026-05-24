# 0002. メンテナンス停滞ツールを除外する (Alfred / Rectangle Free / cmd-eikana ほか)

- **Status**: Accepted
- **Date**: 2026-05-24
- **Deciders**: Daisuke Arakawa

## Context

旧 README には以下が含まれていた:

- **Alfred** (ランチャー)
- **Rectangle** (ウィンドウ管理、Free 版)
- **cmd-eikana / ⌘英かな** (英数/かなトグル)

いずれも 2025 年以降のリリースが事実上止まっている、または macOS 26 で挙動が不安定。新環境に持ち込むメリットが小さい。

## Decision

新 `Brewfile` ではこれらを除外し、以下に置き換える:

| 廃止 | 代替 | 理由 |
|---|---|---|
| Alfred | **Raycast** (Brewfile) + **Vector** (40-non-brew-apps.sh) | 両者ともアクティブ開発。AI / ローカル知識統合が強い |
| Rectangle (Free) | **rectangle-pro** (任意) または **Karabiner-Elements + Stage Manager** | Free 版はメンテ停滞。Pro は別物として継続 |
| cmd-eikana | **Karabiner-Elements** の left_command / right_command → eisuu / kana 割り当て | 同じ機能を実現でき、Karabiner 自体は活発 |

`Brewfile` には `# brew "..."` のコメントすら残さない (誘惑を断つ)。採用理由はこの ADR で参照可能。

## Consequences

- ✅ メンテ停滞ツールが減り、macOS アップグレードでの破損リスクが下がる
- ✅ 入力周りが Karabiner-Elements 一本に集約され、シンプル
- ❌ Alfred の Workflow を多用していたユーザーは移行コストあり (本リポジトリのオーナーは Workflow を使っていない)
- ❌ Rectangle Free の Hot-corner / 矢印キー操作に慣れた手指は再学習が必要

## Alternatives considered

- **Alfred を残す**: 却下。2025 年以降のリリース頻度が著しく低下しており、Raycast / Vector が機能で並ぶか上回る
- **Rectangle (Free) を残す**: 却下。macOS 26 の Stage Manager と挙動が衝突するケースがあり、現代では Karabiner + ネイティブで十分
- **cmd-eikana を Karabiner と併用**: 却下。同じレイヤーで両方が左右コマンドを横取りすると挙動が読みにくい。Karabiner に一元化したほうがデバッグが容易
