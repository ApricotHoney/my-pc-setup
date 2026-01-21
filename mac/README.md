# setup script for MacOS

PCのセットアップを実行するリポジトリです。
環境が変わっていたり、情報が古くなっていると正しく動作しない可能性があるため、実際に使用する場合は自己責任で。
個人的なメモのため、参考程度にお願いします。

## 前提条件

セットアップを始める前に必要な事項を記載します

- GitHubアカウント作成済み
- 各種dotfileを作成済みで、githubリポジトリにて管理されていること
    - 以下をメモするなり控えておきます
        - github_username
        - dotfileを管理しているgithubリポジトリ名

## スクリプトを使った自動セットアップ

基本的な使い方：github_usernameは自分のgithubアカウントのユーザー名に置き換えてください。

```bash
./mac-setup.sh github_username
```

dotfileを入れたリポジトリ名を指定する場合の実行コマンド

```bash
./mac-setup.sh github_username dotfiles
```

例えばgithubアカウントのユーザー名が`hoge`の場合、以下のように実行します。

```bash
./mac-setup.sh hoge
```

dotfileを入れたリポジトリ名を指定

```bash
./mac-setup.sh hoge dotfiles
```

setup.shは以下の内容でdotfileを管理しているgithubリポジトリと同じところに置いています。

```bash
#!/bin/bash

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# エラーで終了する関数
exit_with_error() {
    log_error "$1"
    exit 1
}

# 引数チェック
if [ "$#" -eq 0 ]; then
    echo "使用方法: $0 <github_username> [repository_name]"
    echo "例: $0 hoge my-dotfiles"
    exit_with_error "Githubユーザー名を指定してください。"
fi

GITHUB_USERNAME="$1"
REPO_NAME="${2:-dotfiles}"  # 第2引数がない場合は"dotfiles"をデフォルト値として使用
DOTFILES_DIR="$HOME/.$REPO_NAME"

log_info "セットアップを開始します..."
log_info "Github Username: $GITHUB_USERNAME"
log_info "リポジトリ名: $REPO_NAME"
log_info "インストール先: $DOTFILES_DIR"

# 確認
read -p "続行しますか？(y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit_with_error "セットアップをキャンセルしました。"
fi

# 既存のdotfilesディレクトリをチェック
if [ -d "$DOTFILES_DIR" ]; then
    log_warning "既存の $DOTFILES_DIR ディレクトリが見つかりました。"
    read -p "上書きしますか？既存のファイルは '$DOTFILES_DIR.backup' にバックアップされます (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "既存のdotfilesをバックアップしています..."
        mv "$DOTFILES_DIR" "$DOTFILES_DIR.backup"
    else
        exit_with_error "セットアップをキャンセルしました。"
    fi
fi

# Gitがインストールされているか確認
if ! command -v git &> /dev/null; then
    log_warning "Gitがインストールされていません。インストールを試みます..."
    if command -v brew &> /dev/null; then
        brew install git || exit_with_error "Gitのインストールに失敗しました。"
    else
        exit_with_error "Homebrewがインストールされていません。先にHomebrewをインストールしてください。"
    fi
fi

# リポジトリのクローン
log_info "リポジトリをクローンしています: https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
git clone "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git" "$DOTFILES_DIR" || exit_with_error "リポジトリのクローンに失敗しました。"

# dotfilesディレクトリに移動
cd "$DOTFILES_DIR" || exit_with_error "ディレクトリ $DOTFILES_DIR に移動できませんでした。"

# インストールスクリプトがあれば実行
if [ -f "install.sh" ]; then
    log_info "インストールスクリプトを実行します..."
    chmod +x install.sh
    ./install.sh || exit_with_error "インストールスクリプトの実行に失敗しました。"
else
    # 基本的なシンボリックリンクの作成
    log_info "基本的なdotfilesのシンボリックリンクを作成します..."
    
    # 共通のdotfilesリスト
    dotfiles=(.zshrc .bashrc .bash_profile .gitconfig .vimrc .tmux.conf)
    
    for file in "${dotfiles[@]}"; do
        if [ -f "$DOTFILES_DIR/$file" ]; then
            # 既存のファイルをバックアップ
            if [ -f "$HOME/$file" ]; then
                log_info "既存の $file をバックアップします..."
                mv "$HOME/$file" "$HOME/${file}.backup"
            fi
            
            # シンボリックリンクの作成
            log_info "シンボリックリンクを作成: $file"
            ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
        fi
    done
    
    # 特殊なディレクトリの処理 (.config等)
    if [ -d "$DOTFILES_DIR/.config" ]; then
        log_info ".configディレクトリのシンボリックリンクを作成します..."
        mkdir -p "$HOME/.config"
        
        # .config内のディレクトリごとにシンボリックリンクを作成
        for dir in "$DOTFILES_DIR/.config"/*; do
            if [ -d "$dir" ]; then
                dir_name=$(basename "$dir")
                
                # 既存のディレクトリをバックアップ
                if [ -d "$HOME/.config/$dir_name" ]; then
                    log_info "既存の .config/$dir_name をバックアップします..."
                    mv "$HOME/.config/$dir_name" "$HOME/.config/${dir_name}.backup"
                fi
                
                # シンボリックリンクの作成
                log_info "シンボリックリンクを作成: .config/$dir_name"
                ln -sf "$dir" "$HOME/.config/$dir_name"
            fi
        done
    fi
fi

# macOS設定ファイルがあれば実行
if [ -f "$DOTFILES_DIR/macos.sh" ]; then
    log_info "macOS設定スクリプトが見つかりました。"
    read -p "macOS設定を適用しますか？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "macOS設定を適用しています..."
        chmod +x "$DOTFILES_DIR/macos.sh"
        "$DOTFILES_DIR/macos.sh" || log_warning "一部のmacOS設定の適用に失敗しました。"
    fi
fi

# Brewfileがあれば実行
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    log_info "Brewfileが見つかりました。"
    read -p "Brewfileからパッケージをインストールしますか？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Homebrewがインストールされているか確認
        if ! command -v brew &> /dev/null; then
            log_warning "Homebrewがインストールされていません。インストールを試みます..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit_with_error "Homebrewのインストールに失敗しました。"
        fi
        
        log_info "Brewfileからパッケージをインストールしています..."
        cd "$DOTFILES_DIR" && brew bundle || log_warning "一部のパッケージのインストールに失敗しました。"
    fi
fi

log_success "セットアップが完了しました！"
log_info "新しい設定を有効にするには、ターミナルを再起動するか、以下のコマンドを実行してください:"
log_info "  source ~/.bashrc  # bashを使用している場合"
log_info "  source ~/.zshrc   # zshを使用している場合"

exit 0
```

## スクリプトの説明

自動セットアップスクリプトで実施している内容について説明します。

macはターミナル.appからdefaultsコマンドを実行でき、このdefaultsコマンドを使ってmacの設定を変更することができます。

defaultsコマンドで設定できるものはスクリプト化して実行しています。

```bash
# ---------------------------------------------
# Finder設定関連
# ---------------------------------------------
# 隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -bool TRUE

# .DS_Storeファイルをネットワークドライブで作成しない
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE

# パスバーを表示
defaults write com.apple.finder ShowPathbar -bool TRUE

# ステータスバーを表示
defaults write com.apple.finder ShowStatusBar -bool TRUE

# プレビューを表示
defaults write com.apple.finder ShowPreviewPane -bool TRUE

# 詳細ビューをデフォルトに設定
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# すべてのファイル拡張子を表示
defaults write NSGlobalDomain AppleShowAllExtensions -bool TRUE

# 検索実行時にデフォルトで現在のフォルダを検索
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# 新規Finderウィンドウでホームディレクトリを表示
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# サイドバーにiCloud Drive表示をオンにする
defaults write com.apple.finder SidebarShowiCloudDrive -bool true

# サイドバーに「外部ディスク」を表示する
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

# ---------------------------------------------
# Dock設定関連
# ---------------------------------------------
# Dockを自動的に表示/非表示を有効化
defaults write com.apple.dock autohide -bool TRUE

# ---------------------------------------------
# コントロールセンター設定関連
# ---------------------------------------------
# 時計の日時を秒まで表示
defaults write com.apple.menuextra.clock ShowSeconds -bool TRUE

# ---------------------------------------------
# デスクトップ設定
# ---------------------------------------------
# デスクトップアイコンを非表示
defaults write com.apple.finder CreateDesktop -bool FALSE

# ---------------------------------------------
# トラックパッド設定関連
# ---------------------------------------------
# タップでクリックを有効化
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool TRUE
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool TRUE

# 3本指ドラッグを有効化
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool TRUE
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool TRUE

# ---------------------------------------------
# その他のシステム設定
# ---------------------------------------------
# スペースを自動的に並べ替え
defaults write com.apple.dock mru-spaces -bool FALSE

# ---------------------------------------------
# homebrew
# ---------------------------------------------
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# ---------------------------------------------
# homebrew cask install
# ---------------------------------------------
# ⌘英かな
brew install --cask cmd-eikana

```

設定を反映するには、各コマンド実行後に関連するアプリケーションを再起動する必要があります：

```bash
# Finderの再起動
killall Finder

# Dockの再起動
killall Dock

# システム設定の変更を反映
killall SystemUIServer
```

## 設定反映確認

設定反映結果を目視で確認していく

### Finder設定

#### 一般

![alt text](image-1.png)

#### タグ

変更なし

#### サイドバー

![alt text](image.png)

#### 詳細

![alt text](image-2.png)

`表示`メニューから以下の表示を有効化

- パスバー
- ステータスバー
- プレビュー

隠しファイルを表示

`Command + Shift + ピリオド（.）`ショートカットキーで有効化するか、以下コマンドをコンソールに入力し実行します

```
defaults write com.apple.finder AppleShowAllFiles TRUE
killall Finder
```

.DS_Storeファイルを作成しないよう、以下コマンドをコンソールに入力し実行します

```
defaults write com.apple.desktopservices DSDontWriteNetworkStores True
killall Finder
```

## システム設定

### ディスプレイ

スペースを拡大
輝度を自動調節:ON
TrueTone:ON

### デスクトップのアイコン・フォルダを非表示

`デスクトップとDock` > `デスクトップとステージマネージャ` > `項目を表示`の`デスクトップに`のチェックを外す

### キーボード

#### IMEインストール

- Google日本語入力

![alt text](image-3.png)

### トラックパッド設定

- `システム設定` > `トラックパッド` > `ポイントとクリック`タブ > `タップでクリック`を有効にする

### アクセシビリティ

- `システム設定` > `アクセシビリティ` > `マウスとトラックパッド` > `トラックパッドオプション`を開き、以下を設定する
    - 「ドラッグにトラックパッドを使用」(または「ドラッグを有効にする」) をオンにします。
    - ポップアップメニューからドラッグ方法として「3 本指のドラッグ」を選択し、OKをクリックします。

- [公式ページ：Mac トラックパッドで「3 本指のドラッグ」を有効にする](https://support.apple.com/ja-jp/102341)


![alt text](image-4.png)

### ブラウザ

入れたいものだけコメントアウトをはずす

# Microsoft Edge
# brew install --cask microsoft-edge
# Chrome
# brew install --cask google-chrome
# firefox
# brew install --cask firefox
# arc
# brew install --cask arc
# vivaldi
# brew install --cask vivaldi
# zen

# Floorp
# brew install --cask floorp
# sleipnir
# brew install --cask sleipnir
# Lunascape

# コミュニケーションツール
- Spark Desktop
- Discord
- Slack
# エディタ
- VSCode
# ターミナル
- Hyper
# AIアシスタント
- AmazonQ
- claude
- chatGPT
- perplexity
# development tools
- git
- Xcode Command Line Tools
- volta

# ネットワーク
- Cloudflare WARP
- Tailscale
# ウィンドウ操作
- Rectangle
# ランチャー
- Raycast
# パスワードマネージャー
- Bitwarden
# プロジェクト、タスク管理
- Notion
- Notion Calender
