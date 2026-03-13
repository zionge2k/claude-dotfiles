# TODO(linux): Homebrew path differs — /home/linuxbrew/.linuxbrew/opt/openjdk@17/bin
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
alias dcl="docker compose -f docker-compose-local.yml"

# SW Campus
unalias sws 2>/dev/null
sws() {
  cd /Users/iseong/projects/software-campus/sw-campus-server
  if [[ "$1" == "-x" ]]; then
    ./gradlew :sw-campus-api:bootRun --args="--spring.profiles.active=local" -x test -q
  else
    ./gradlew :sw-campus-api:bootRun --args="--spring.profiles.active=local" -q
  fi
}
alias swc='cd /Users/iseong/projects/software-campus/sw-campus-client && pnpm dev'

# Ecommerce Shop
unalias ess 2>/dev/null
ess() {
  cd /Users/iseong/projects/ecommerce-shop
  if [[ "$1" == "-x" ]]; then
    ./gradlew :shop-api:bootRun --args="--spring.profiles.active=local" -x test -q
  else
    ./gradlew :shop-api:bootRun --args="--spring.profiles.active=local" -q
  fi
}
alias esc='cd /Users/iseong/projects/ecommerce-shop/ecommerce-frontend && npm run dev'

# Claude Code - agent teams split-pane mode
alias claude='claude --teammate-mode tmux'
alias cl='claude'
alias cld='claude --dangerously-skip-permissions --teammate-mode tmux'
alias cc-commit='claude --dangerously-skip-permissions --teammate-mode tmux -p "/commit" --allowedTools "Bash,Read,Grep"'
alias cc-push='claude --dangerously-skip-permissions --teammate-mode tmux -p "/commit --push" --allowedTools "Bash,Read,Grep"'
alias plugins-cc='npx claude-code-templates@latest --plugins'
alias chats-cc='npx claude-code-templates@latest --chats'
alias clean-mac='npx mac-cleaner-cli'

# --- Homebrew ---
# TODO(linux): Change Homebrew path — Linux uses /home/linuxbrew/.linuxbrew/bin/brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Morning routine: brew upgrade + cleanup
alias bru='brew upgrade && brew cleanup'

# --- Safe delete ---
# TODO(linux): Install trash-cli (npm i -g trash-cli) or use trash-put from trash-d
alias rm='trash'

# --- Editor ---
alias vi='nvim'

# --- tmux ---
alias ta='tmux attach'

# --- ls replacements ---
alias ll='lsd -aFlht'
alias ls='eza --color=always --icons=always -a -1 --git'

# --- fd/rg enhanced ---
alias fdm='fd --hidden --no-ignore'
alias rgm='rg --no-ignore --hidden'

# --- Git aliases (shell level) ---
alias greset='git add .; git reset --hard HEAD'

# --- bat theme ---
export BAT_THEME=GitHub

# --- vivid LS_COLORS (light theme) ---
export LS_COLORS="$(vivid generate one-light)"

# --- TheFuck ---
if command -v thefuck &>/dev/null; then
  eval $(thefuck --alias)
  eval $(thefuck --alias fk)
fi

# --- Zoxide (better cd) ---
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# --- FZF setup ---
if command -v fzf &>/dev/null; then
  eval "$(fzf --zsh)"

  # Light mode colors (GitHub Light theme)
  fg="#24292f"
  bg="#ffffff"
  bg_highlight="#f6f8fa"
  purple="#8250df"
  blue="#0969da"
  cyan="#1f883d"
  export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

  # Use fd for file listing
  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

  _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
  _fzf_compgen_dir() { fd --type=d --hidden --exclude .git . "$1"; }

  export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

  _fzf_comprun() {
    local command=$1
    shift
    case "$command" in
      cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
      export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
      ssh)          fzf --preview 'dig {}'                   "$@" ;;
      *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
    esac
  }
fi

# --- History setup ---
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# --- Vim mode ---
set -o vi

# --- Locale ---
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8

# --- Zsh plugins (if installed) ---
# TODO(linux): Change plugin paths — Linux Homebrew uses /home/linuxbrew/.linuxbrew/share/
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Autojump ---
# TODO(linux): Change autojump path — Linux Homebrew uses /home/linuxbrew/.linuxbrew/etc/
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# --- Starship prompt ---
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# --- Useful functions ---
# fzf git branch checkout
fsb() {
  local branches branch
  branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
  branch=$(echo "$branches" | fzf -d $((2 + $(echo "$branches" | wc -l))) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fzf git log interactive
fshow() {
  git log --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index \
    --bind "ctrl-m:execute:(grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R') <<< {}"
}

# Kill process by port
kill_by_port() {
  if [ -z "$1" ]; then
    echo "Usage: kill_by_port <port>"
    return 1
  fi
  lsof -ti TCP:"$1" | xargs kill -9 2>/dev/null && echo "Killed process on port $1" || echo "No process on port $1"
}

# yazi file manager with cd integration
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# --- Claude Code dynamic MCP loading ---
export ENABLE_LSP_TOOLS=1
export ENABLE_TOOL_SEARCH=true

# --- SDKMAN (must be at the end) ---
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# --- NVM ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- pyenv ---
if command -v pyenv &>/dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
