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
      local CONFIG_DIRS=(agents skills hooks docs templates)

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

  cd "$DOTFILES_DIR"

  # ── 1. Clear ONLY non-symlink *real file* conflicts ──────────────────
  # Single tracked files that may exist as real files on first migration.
  # Safe to remove: backup_existing() already copied them. Directories are
  # intentionally NOT rm'd here — see step 2 for why (the old dir rm was the
  # root cause of the deploy-abort data loss: with --no-folding, dirs like
  # agents/ are always real dirs, so a blind `rm -rf` fired on every re-run
  # and relied on stow to recreate; a stow abort then wiped them permanently).
  local REAL_FILE_CONFLICTS=(
    .tmux.conf .zshrc .zprofile
    .config/ghostty/config .config/starship.toml
    .config/nvim/lua/plugins/vim-tmux-navigator.lua .config/keybindings-guide.md
    .claude/CLAUDE.md .claude/settings.json .claude/keybindings.json
    .claude/code-review.yml .claude/claude-watch-hook.sh .claude/README.md
    ".claude/Prompt Enhancer.md" .claude/Prompt-Enhancer2.md
  )
  for f in "${REAL_FILE_CONFLICTS[@]}"; do
    [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && rm -f "$HOME/$f" && info "  Cleared real file ~/$f (backed up)"
  done

  # ── 2. Pre-flight: verify stow can complete with NO conflicts ─────────
  # `stow -R` (restow) manages its own symlink trees transactionally and is
  # safe to run repeatedly. We dry-run it first; if ANY unexpected conflict
  # remains (e.g. new runtime junk not yet in .stow-local-ignore), we abort
  # BEFORE touching the live deployment — never destroy a working setup.
  local PREFLIGHT
  PREFLIGHT="$(stow -R --no-folding -n -t "$HOME" -v . 2>&1)" || true
  if echo "$PREFLIGHT" | grep -qiE "conflict|aborted|cannot stow"; then
    error "Stow pre-flight detected conflicts — aborting WITHOUT any changes:"
    echo "$PREFLIGHT" | grep -iE "conflict|aborted|cannot stow|over existing" >&2
    error "Resolve the targets above, or add them to .stow-local-ignore, then re-run."
    exit 1
  fi

  # ── 3. Commit: restow (transactional; aborts cleanly on surprise) ─────
  stow -R --no-folding -t "$HOME" -v .

  # ── 4. Make hook/script symlinks executable (resolves through symlink) ─
  local EXEC_SCRIPTS=(
    hooks/notify.sh hooks/check-env-files.sh hooks/check-hardcoded-paths.sh
    hooks/check-sensitive-files.sh hooks/update-brewfile.sh
    hooks/log-bash-command.sh hooks/post-edit-check.sh
    hooks/session-metrics.sh hooks/vis-serve.sh claude-watch-hook.sh
  )
  for s in "${EXEC_SCRIPTS[@]}"; do
    chmod +x "$CLAUDE_DIR/$s" 2>/dev/null || true
  done

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
    "msbaek/msbaek-claude-plugins"
    "obra/superpowers-marketplace"
  )
  for mp in "${MARKETPLACES[@]}"; do
    claude plugin marketplace add "$mp" 2>/dev/null || true
  done

  info "Installing plugins..."

  # Official plugins
  local PLUGINS=(
    "frontend-design@claude-plugins-official"
    "code-review@claude-plugins-official"
    "github@claude-plugins-official"
    "feature-dev@claude-plugins-official"
    "playwright@claude-plugins-official"
    "serena@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "pr-review-toolkit@claude-plugins-official"
    "atlassian@claude-plugins-official"
    "plugin-dev@claude-plugins-official"
    "explanatory-output-style@claude-plugins-official"
    "greptile@claude-plugins-official"
    "hookify@claude-plugins-official"
    "learning-output-style@claude-plugins-official"
    "Notion@claude-plugins-official"
  )

  # LSP plugins (now part of claude-plugins-official marketplace)
  local LSP_PLUGINS=(
    "jdtls-lsp@claude-plugins-official"
    "kotlin-lsp@claude-plugins-official"
    "typescript-lsp@claude-plugins-official"
    "pyright-lsp@claude-plugins-official"
  )

  # Third-party plugins
  local THIRD_PARTY=(
    "msbaek-tdd@msbaek-claude-plugins"
    "superpowers@superpowers-marketplace"
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
