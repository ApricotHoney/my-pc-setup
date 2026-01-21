# setup script for Raspberry Pi

このセットアップスクリプトは次のことを行います

1. 必要なパッケージ（zsh、git、curl、wget）をインストール
2. ZSHをデフォルトシェルとして設定
3. Zpreztoをインストール
4. GitHubのdotfilesリポジトリをクローンして設定
5. 既存の設定ファイルをバックアップ
6. dotfilesの設定をシンボリックリンクで適用

### 使用方法

1. スクリプトをRaspberry Piにダウンロード
2. スクリプト内の`yourusername`を実際のGitHubユーザー名に変更
3. スクリプトに実行権限を付与：`chmod +x setup_zsh_zprezto.sh`
4. スクリプトを実行：`./setup_zsh_zprezto.sh`

### カスタマイズのヒント

- dotfilesリポジトリの構造は通常、`zsh/zshrc`、`zsh/zpreztorc`などのファイルを含む形式にします
- 特定のZpreztoテーマを使用する場合は、`zprezto-themes`ディレクトリにテーマファイルを配置します
- `.zshrc`にはエイリアスやパス設定など、個人的な設定を追加できます

スクリプト実行後、一度ログアウトして再ログインすると、ZSHとZpreztoが新しいデフォルトシェルとして機能します。