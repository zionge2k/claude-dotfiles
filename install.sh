#!/usr/bin/env bash
set -euo pipefail

# Claude Code Dotfiles Installer
# Supports: macOS (Homebrew), Arch Linux (pacman)

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
OS="$(uname -s)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ─────────────────────────────────────────────
# 1. OS Detection & Dependencies
# ─────────────────────────────────────────────
install_deps() {
  info "Installing dependencies for $OS..."

  case "$OS" in
    Darwin)
      if ! command -v brew &>/dev/null; then
        error "Homebrew not found. Install: https://brew.sh"
        exit 1
      fi
      brew install stow jq node terminal-notifier 2>/dev/null || true
      ;;
    Linux)
      if command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm stow jq nodejs npm libnotify 2>/dev/null || true
      else
        error "Unsupported Linux distro. Install manually: stow, jq, nodejs, libnotify"
        exit 1
      fi
      ;;
    *)
      error "Unsupported OS: $OS"
      exit 1
      ;;
  esac

  info "Dependencies installed."
}

# ─────────────────────────────────────────────
# 2. Backup existing config
# ─────────────────────────────────────────────
backup_existing() {
  local BACKUP_DIR="$HOME/.dotfiles-backup.$(date +%Y%m%d%H%M%S)"
  local NEEDS_BACKUP=false

  # Terminal config files that stow will manage
  local TERMINAL_FILES=(.tmux.conf .zshrc .zprofile)
  local TERMINAL_CONFIG_DIRS=(.config/ghostty .config/starship.toml .config/nvim/lua/plugins/vim-tmux-navigator.lua .config/keybindings-guide.md)

  # Check if any non-symlink files exist that would conflict
  for f in "${TERMINAL_FILES[@]}" "${TERMINAL_CONFIG_DIRS[@]}"; do
    [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && NEEDS_BACKUP=true && break
  done
  [ -d "$CLAUDE_DIR" ] && NEEDS_BACKUP=true

  if [ "$NEEDS_BACKUP" = true ]; then
    warn "Backing up existing config files to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    # Backup terminal config files (only non-symlinks)
    for f in "${TERMINAL_FILES[@]}"; do
      [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && cp "$HOME/$f" "$BACKUP_DIR/" 2>/dev/null || true
    done
    for f in "${TERMINAL_CONFIG_DIRS[@]}"; do
      if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$f")"
        cp -r "$HOME/$f" "$BACKUP_DIR/$f" 2>/dev/null || true
      fi
    done

    # Backup Claude config files (not runtime data)
    if [ -d "$CLAUDE_DIR" ]; then
      local CONFIG_ITEMS=(
        CLAUDE.md settings.json keybindings.json code-review.yml
        claude-watch-hook.sh README.md
        "Prompt Enhancer.md" Prompt-Enhancer2.md
      )
      local CONFIG_DIRS=(agents skills hooks docs)

      mkdir -p "$BACKUP_DIR/.claude"
      for item in "${CONFIG_ITEMS[@]}"; do
        [ -e "$CLAUDE_DIR/$item" ] && cp "$CLAUDE_DIR/$item" "$BACKUP_DIR/.claude/" 2>/dev/null || true
      done
      for dir in "${CONFIG_DIRS[@]}"; do
        [ -d "$CLAUDE_DIR/$dir" ] && cp -r "$CLAUDE_DIR/$dir" "$BACKUP_DIR/.claude/" 2>/dev/null || true
      done
    fi

    info "Backup completed: $BACKUP_DIR"
  fi
}

# ─────────────────────────────────────────────
# 3. Deploy with GNU Stow
# ─────────────────────────────────────────────
deploy_dotfiles() {
  info "Deploying dotfiles with GNU Stow..."

  # Ensure target directories exist
  mkdir -p "$CLAUDE_DIR"
  mkdir -p "$HOME/.config/ghostty"
  mkdir -p "$HOME/.config/nvim/lua/plugins"

  # Remove non-symlink terminal config files that would conflict with stow
  local TERMINAL_FILES=(.tmux.conf .zshrc .zprofile)
  for f in "${TERMINAL_FILES[@]}"; do
    [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && rm "$HOME/$f" && info "  Removed ~/$f (backed up)"
  done

  local TERMINAL_CONFIG_FILES=(.config/ghostty/config .config/starship.toml .config/nvim/lua/plugins/vim-tmux-navigator.lua .config/keybindings-guide.md)
  for f in "${TERMINAL_CONFIG_FILES[@]}"; do
    [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && rm "$HOME/$f" && info "  Removed ~/$f (backed up)"
  done

  # Remove existing Claude config files/dirs that would conflict with stow
  local STOW_ITEMS=(
    CLAUDE.md settings.json keybindings.json code-review.yml
    claude-watch-hook.sh README.md
    "Prompt Enhancer.md" Prompt-Enhancer2.md
  )
  local STOW_DIRS=(agents hooks docs)

  for item in "${STOW_ITEMS[@]}"; do
    [ -e "$CLAUDE_DIR/$item" ] && [ ! -L "$CLAUDE_DIR/$item" ] && rm "$CLAUDE_DIR/$item" 2>/dev/null || true
  done
  for dir in "${STOW_DIRS[@]}"; do
    [ -d "$CLAUDE_DIR/$dir" ] && [ ! -L "$CLAUDE_DIR/$dir" ] && rm -rf "$CLAUDE_DIR/$dir" 2>/dev/null || true
  done

  # Skills: dynamically detect from dotfiles repo and remove non-symlink conflicts
  if [ -d "$DOTFILES_DIR/.claude/skills" ]; then
    for skill_dir in "$DOTFILES_DIR/.claude/skills"/*/; do
      skill_name="$(basename "$skill_dir")"
      [ -d "$CLAUDE_DIR/skills/$skill_name" ] && [ ! -L "$CLAUDE_DIR/skills/$skill_name" ] && rm -rf "$CLAUDE_DIR/skills/$skill_name" 2>/dev/null || true
    done
  fi

  # Run stow with --no-folding to avoid symlinking entire directories
  cd "$DOTFILES_DIR"
  stow --no-folding -t "$HOME" -v .

  # Make scripts executable
  chmod +x "$CLAUDE_DIR/hooks/notify.sh" 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/claude-watch-hook.sh" 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/hooks/check-env-files.sh" 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/hooks/check-hardcoded-paths.sh" 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/hooks/check-sensitive-files.sh" 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/hooks/update-brewfile.sh" 2>/dev/null || true

  info "Dotfiles deployed successfully."
}

# ─────────────────────────────────────────────
# 4. Install Plugins & Marketplaces
# ─────────────────────────────────────────────
install_plugins() {
  if ! command -v claude &>/dev/null; then
    warn "Claude Code CLI not found. Skipping plugin installation."
    warn "Install Claude Code first, then re-run: $0 --plugins-only"
    return
  fi

  info "Setting up plugin marketplaces..."

  # Add marketplaces
  local MARKETPLACES=(
    "anthropics/claude-plugins-official"
    "anthropics/claude-code-lsps"
    "msbaek/msbaek-claude-plugins"
  )
  for mp in "${MARKETPLACES[@]}"; do
    claude plugin marketplace add "$mp" 2>/dev/null || true
  done

  info "Installing plugins..."

  # Official plugins
  local PLUGINS=(
    "superpowers@claude-plugins-official"
    "frontend-design@claude-plugins-official"
    "code-review@claude-plugins-official"
    "github@claude-plugins-official"
    "feature-dev@claude-plugins-official"
    "code-simplifier@claude-plugins-official"
    "playwright@claude-plugins-official"
    "serena@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "pr-review-toolkit@claude-plugins-official"
    "atlassian@claude-plugins-official"
    "plugin-dev@claude-plugins-official"
    "explanatory-output-style@claude-plugins-official"
    "claude-md-management@claude-plugins-official"
    "greptile@claude-plugins-official"
    "hookify@claude-plugins-official"
    "learning-output-style@claude-plugins-official"
    "playground@claude-plugins-official"
    "Notion@claude-plugins-official"
  )

  # LSP plugins
  local LSP_PLUGINS=(
    "jdtls@claude-code-lsps"
    "kotlin-lsp@claude-code-lsps"
    "vtsls@claude-code-lsps"
    "pyright@claude-code-lsps"
  )

  # Third-party plugins
  local THIRD_PARTY=(
    "msbaek-tdd@msbaek-claude-plugins"
  )

  for plugin in "${PLUGINS[@]}" "${LSP_PLUGINS[@]}" "${THIRD_PARTY[@]}"; do
    info "  Installing $plugin..."
    claude plugin install "$plugin" 2>/dev/null || warn "  Failed: $plugin (may need manual install)"
  done

  info "Plugin installation completed."
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
main() {
  echo "═══════════════════════════════════════════"
  echo "  Claude Code Dotfiles Installer"
  echo "  OS: $OS | Target: ~/.claude/"
  echo "═══════════════════════════════════════════"
  echo

  case "${1:-}" in
    --plugins-only)
      install_plugins
      ;;
    --no-plugins)
      install_deps
      backup_existing
      deploy_dotfiles
      ;;
    *)
      install_deps
      backup_existing
      deploy_dotfiles
      install_plugins
      ;;
  esac

  echo
  info "Done! Restart Claude Code to apply changes."
  info "Options: --plugins-only | --no-plugins"
}

main "$@"
