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