# Work Journal

リポジトリ全体に渡る作業のログを **日付単位 (`YYYY-MM-DD-<topic>.md`)** で残す場所。

## なぜジャーナルを残すか

- **agent (人間 / AI) が「いつ何を入れたか」を git log だけに頼らず追える**: コミット粒度より荒く、ADR より具体的な「その日の意図と結果」を残す
- ADR (`mac/docs/decisions/`) は **判断単位**、journal は **作業単位**。両者は補完関係
- 数ヶ月後に「なんでこのスクリプトを書いたんだっけ」を 10 秒で思い出すための短期記憶
- 新しく入った agent はジャーナルを新しい順に読めば、リポジトリの "近況" がわかる

## 書き方

ファイル: `docs/journal/YYYY-MM-DD-<short-topic>.md`

テンプレート:

```markdown
# YYYY-MM-DD — <topic>

## 目的
<この日の作業で何を達成したかったか>

## 実装したもの
<ファイル / ディレクトリ単位で何を足したか・変えたか>

## 設計上の選択
<採用した方針と理由。詳しくは ADR にリンク>

## 検証
<どう動作確認したか (dry-run, syntax check, brew bundle list 等)>

## 残作業 / TODO
<次回引き継ぐべきこと>

## 関連
<関連 PR / ADR / Issue / 外部ドキュメント>
```

## 一覧

| 日付 | トピック | リンク |
|---|---|---|
| 2026-05-24 | mac/ の 2026年5月版 bootstrap 整備 + AGENTS.md / docs / ADR 追加 | [2026-05-24-mac-bootstrap-and-agents.md](./2026-05-24-mac-bootstrap-and-agents.md) |
