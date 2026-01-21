#!/bin/bash

# Raspberry Pi ZSH & Zprezto Setup Script
# ---------------------------------------
# This script sets up ZSH as the default shell and installs Zprezto
# with configuration from your dotfiles repository.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

# Print success message
print_success() {
    echo -e "${GREEN}==>${NC} $1"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}==>${NC} $1"
}

# Print error message
print_error() {
    echo -e "${RED}==>${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install required packages
install_prerequisites() {
    print_message "Installing prerequisites..."
    
    # Update package lists
    sudo apt-get update
    
    # Install required packages
    sudo apt-get install -y zsh git curl wget
    
    print_success "Prerequisites installed successfully."
}

# Install ZSH
install_zsh() {
    print_message "Installing and configuring ZSH..."
    
    # Check if ZSH is already installed
    if command_exists zsh; then
        print_warning "ZSH is already installed."
    else
        sudo apt-get install -y zsh
        print_success "ZSH installed successfully."
    fi
    
    # Set ZSH as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        print_message "Setting ZSH as default shell..."
        sudo chsh -s $(which zsh) $USER
        print_success "ZSH set as default shell. Please log out and log back in for changes to take effect."
    else
        print_warning "ZSH is already the default shell."
    fi
}

# Install Zprezto
install_zprezto() {
    print_message "Installing Zprezto..."
    
    # Check if Zprezto is already installed
    if [ -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
        print_warning "Zprezto is already installed. Updating..."
        cd "${ZDOTDIR:-$HOME}/.zprezto"
        git pull && git submodule update --init --recursive
    else
        # Clone Zprezto
        git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    fi
    
    print_success "Zprezto installed successfully."
}

# Setup dotfiles
setup_dotfiles() {
    print_message "Setting up dotfiles..."
    
    # Define dotfiles directory
    DOTFILES_DIR="${ZDOTDIR:-$HOME}/dotfiles"
    
    # Clone dotfiles repository if it doesn't exist
    if [ ! -d "$DOTFILES_DIR" ]; then
        print_message "Cloning dotfiles repository..."
        # Replace with your actual dotfiles repository URL
        git clone https://github.com/yourusername/dotfiles.git "$DOTFILES_DIR"
    else
        print_warning "Dotfiles repository already exists. Updating..."
        cd "$DOTFILES_DIR"
        git pull
    fi
    
    # Create a backup directory for existing dotfiles
    BACKUP_DIR="${ZDOTDIR:-$HOME}/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup and link zprezto configuration files
    for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
        # Create backup if file exists and is not a symlink
        if [ -f "${ZDOTDIR:-$HOME}/.$(basename "$rcfile")" ] && [ ! -L "${ZDOTDIR:-$HOME}/.$(basename "$rcfile")" ]; then
            mv "${ZDOTDIR:-$HOME}/.$(basename "$rcfile")" "$BACKUP_DIR/"
        fi
    done
    
    # Link any custom dotfiles from your repository
    for file in "$DOTFILES_DIR"/zsh/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            target="${ZDOTDIR:-$HOME}/.${filename}"
            
            # Backup existing file if it's not a symlink
            if [ -f "$target" ] && [ ! -L "$target" ]; then
                mv "$target" "$BACKUP_DIR/"
            fi
            
            # Create symlink
            ln -sf "$file" "$target"
            print_message "Linked $filename"
        fi
    done
    
    # If there are specific zprezto theme files, link them
    if [ -d "$DOTFILES_DIR/zprezto-themes" ]; then
        mkdir -p "${ZDOTDIR:-$HOME}/.zprezto/modules/prompt/functions"
        for theme in "$DOTFILES_DIR"/zprezto-themes/*; do
            if [ -f "$theme" ]; then
                theme_name=$(basename "$theme")
                ln -sf "$theme" "${ZDOTDIR:-$HOME}/.zprezto/modules/prompt/functions/$theme_name"
                print_message "Linked theme $theme_name"
            fi
        done
    fi
    
    print_success "Dotfiles setup completed."
}

# Create default .zshrc if it doesn't exist in dotfiles
create_default_zshrc() {
    # Check if .zshrc exists in dotfiles
    if [ ! -f "$DOTFILES_DIR/zsh/zshrc" ] && [ ! -f "${ZDOTDIR:-$HOME}/.zshrc" ]; then
        print_message "Creating default .zshrc..."
        
        cat > "${ZDOTDIR:-$HOME}/.zshrc" << 'EOF'
# Source Prezto
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

# Aliases
alias ll='ls -la'
alias update='sudo apt-get update && sudo apt-get upgrade'
alias reload='source ~/.zshrc'

# Path additions
export PATH=$HOME/bin:$PATH

# Raspberry Pi specific settings
export EDITOR='nano'
EOF
        print_success "Default .zshrc created."
    fi
}

# Main function
main() {
    print_message "Starting Raspberry Pi ZSH & Zprezto setup..."
    
    install_prerequisites
    install_zsh
    install_zprezto
    setup_dotfiles
    create_default_zshrc
    
    print_success "Setup completed successfully!"
    print_message "Please log out and log back in to start using ZSH with Zprezto."
    print_message "Or run 'zsh' to try it without logging out."
}

# Run the script
main