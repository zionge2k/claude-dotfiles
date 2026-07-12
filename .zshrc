# TODO(linux): Homebrew path differs — /home/linuxbrew/.linuxbrew/opt/openjdk@17/bin
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
alias dcl="docker compose -f docker-compose-local.yml"

# Claude Code - agent teams split-pane mode (teammateMode lives in settings.json)
alias cl='claude'
alias cld='claude --dangerously-skip-permissions'
alias cc-commit='claude --dangerously-skip-permissions -p "/commit" --allowedTools "Bash,Read,Grep"'
alias cc-push='claude --dangerously-skip-permissions -p "/commit --push" --allowedTools "Bash,Read,Grep"'
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
# rm as a function: flags (-rf etc.) are dropped, files always go to Trash.
# Safer than `alias rm='trash'` which chokes on flag-mixed calls like `rm -rf dir`.
rm() {
  local args=()
  for arg in "$@"; do
    [[ "$arg" == -* ]] || args+=("$arg")
  done
  if (( ${#args[@]} > 0 )); then
    command trash "${args[@]}"
  fi
}

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

# fzf git log interactive — live diff preview, enter=view, ctrl-o=checkout
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort --preview \
         'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1 ; }; f {}' \
      --header "enter to view, ctrl-o to checkout" \
      --bind "q:abort,ctrl-f:preview-page-down,ctrl-b:preview-page-up" \
      --bind "ctrl-o:become:(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs git checkout)" \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF" --preview-window=right:60%
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
  command rm -f -- "$tmp"
}

# --- tmux session switcher (from msbaek/dotfiles) ---
# fzf-pick a tmux session → switch (inside) or attach (outside). New name = create detached.
ts() {
  local session
  session=$(tmux list-sessions -F '#S' 2>/dev/null | fzf \
    --prompt="tmux session> " --height=40% --reverse \
    --preview 'tmux list-windows -t {} -F "#I: #W"' \
    --print-query | tail -1)
  [[ -z "$session" ]] && return

  # Create detached if the name doesn't exist. '=' forces exact match —
  # `has-session -t` alone does prefix/fnmatch matching, so a new name that is
  # a prefix of an existing session would falsely match it.
  tmux has-session -t "=$session" 2>/dev/null || tmux new-session -d -s "$session"

  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "=$session"
  else
    tmux attach -t "=$session"
  fi
}

# --- cj: Claude project jump (adapted from msbaek/dotfiles) ---
# Project list: ~/.config/cc-projects.list (one path per line, optional @memo tag).
# Open project → jump to its tmux pane; closed → cd in the current pane.

# _cj_load <file>: project list file → 'path<TAB>session' (strip comments/blank, parse @memo).
_cj_load() {
  awk '
    {
      sub(/#.*/, "")
      gsub(/^[ \t]+|[ \t]+$/, "")
    }
    /^$/ { next }
    {
      session = "work"
      if ($0 ~ /[ \t]@memo[ \t]*$/) {
        session = "memo"
        sub(/[ \t]+@memo[ \t]*$/, "")
        gsub(/[ \t]+$/, "")
      }
      print $0 "\t" session
    }
  ' "$1"
}

# _cj_match <expanded_path...>: project paths (args) + tmux 'target|path' (stdin)
#   → per project 'state|target|path|name' (state ∈ open/closed/missing).
#   Both sides normalized via ${:A}; first tmux match wins for duplicate paths.
_cj_match() {
  local -A pane_by_norm
  local target path norm
  while IFS='|' read -r target path; do
    [ -n "$path" ] || continue
    norm="${path:A}"
    [ -n "${pane_by_norm[$norm]}" ] || pane_by_norm[$norm]="$target"
  done

  local p name tgt pnorm
  for p in "$@"; do
    name="${p:t}"
    if [[ ! -d "$p" ]]; then
      print -r -- "missing||$p|$name"
      continue
    fi
    pnorm="${p:A}"
    tgt="${pane_by_norm[$pnorm]}"
    if [ -n "$tgt" ]; then
      print -r -- "open|$tgt|$p|$name"
    else
      print -r -- "closed||$p|$name"
    fi
  done
}

# _cj_rows: stdin 'state|target|path|name' → 'sortkey\tdisplay\tstate\tpayload'.
#   Sort: open🟢(0) → closed⚪(1) → missing⚠(2). payload = open ? target : path.
_cj_rows() {
  awk -F'|' '
    {
      state=$1; target=$2; path=$3; name=$4
      if (state=="open")        { key=0; sym="🟢"; loc="  ("target")" }
      else if (state=="closed") { key=1; sym="⚪"; loc="" }
      else                      { key=2; sym="⚠"; loc="  (missing)" }
      payload=(state=="open")?target:path
      printf "%d\t%s %-26s%s\t%s\t%s\n", key, sym, name, loc, state, payload
    }' | sort -s -n -k1,1
}

# _cc_goto <target>: jump to tmux target (session:window.pane).
# Outside tmux = attach, same session = select window/pane, other session = switch-client.
# Adapted from upstream cw.zsh: the aerospace/Ghostty multi-window branch is replaced
# with switch-client for a single-terminal + multi-session tmux workflow.
_cc_goto() {
  local target="$1"
  [ -n "$target" ] || return

  if [ -z "$TMUX" ]; then tmux attach -t "$target"; return; fi

  local sess="${target%%:*}" win="${target%.*}"
  local cur; cur="$(tmux display -p '#{session_name}' 2>/dev/null)"

  tmux select-window -t "$win" 2>/dev/null
  tmux select-pane -t "$target" 2>/dev/null

  [ "$sess" = "$cur" ] && return
  tmux switch-client -t "=$sess"
}

# cj [query]: fzf-pick a project → jump to its pane if open, cd if closed.
cj() {
  local file="$HOME/.config/cc-projects.list"
  [[ -f "$file" ]] || { echo "[cj] not found: $file"; return 1; }

  # config → _cj_load(path\tsession), keep path only, expand leading ~
  local -a lines projects
  lines=( ${(f)"$(_cj_load "$file")"} )
  (( ${#lines} )) || { echo "[cj] empty list: $file"; return 1; }
  local line
  for line in "${lines[@]}"; do
    projects+=( "${line%%$'\t'*}" )
  done
  projects=( ${projects/#\~/$HOME} )

  # Collect open pane paths. Outside tmux, skip open-detection → everything closed → cd.
  local tmux_data=""
  [[ -n "$TMUX" ]] && tmux_data="$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}' 2>/dev/null)"

  local sel
  sel=$(_cj_match "${projects[@]}" <<< "$tmux_data" \
        | _cj_rows \
        | fzf --ansi --delimiter=$'\t' --with-nth=2 --query="${1:-}" \
              --header='🟢 open / ⚪ closed / ⚠ missing │ Enter=jump or cd' --reverse) || return
  [ -n "$sel" ] || return

  local state payload
  state=$(printf '%s' "$sel" | cut -d$'\t' -f3)
  payload=$(printf '%s' "$sel" | cut -d$'\t' -f4)
  [ -n "$payload" ] || return

  if [[ "$state" == "open" ]]; then
    _cc_goto "$payload"
  else
    cd "$payload"
  fi
}

# --- Memory diagnostics (from msbaek/dotfiles) ---
# Free memory in GB. free (immediately available) + inactive (reclaimable) = usable.
# Large compressed value = memory pressure.
memfree() {
  local page=16384
  local stats
  stats=$(vm_stat)
  local free inactive compressed wired total
  free=$(echo "$stats"       | awk '/Pages free/                 {gsub(/\./,"",$NF); print $NF}')
  inactive=$(echo "$stats"   | awk '/Pages inactive/             {gsub(/\./,"",$NF); print $NF}')
  compressed=$(echo "$stats" | awk '/Pages stored in compressor/ {gsub(/\./,"",$NF); print $NF}')
  wired=$(echo "$stats"      | awk '/Pages wired down/           {gsub(/\./,"",$NF); print $NF}')
  total=$(sysctl -n hw.memsize)
  python3 -c "
p=$page; f=$free; i=$inactive; c=$compressed; w=$wired; t=$total
gb=lambda n: n*p/1024**3
tg=gb(t/p)
print(f'Total       {gb(t/p):5.1f} GB')
print(f'Free        {gb(f):5.2f} GB  ({gb(f)/tg*100:.1f}%)  — immediately available')
print(f'Inactive    {gb(i):5.2f} GB              — reclaimable (counts as usable)')
print(f'Usable      {gb(f+i):5.2f} GB  ({gb(f+i)/tg*100:.1f}%)  — free + inactive')
print(f'Compressed  {gb(c):5.1f} GB              — memory pressure indicator')
print(f'Wired       {gb(w):5.2f} GB              — OS kernel, not reclaimable')
"
}

# Diagnose memory *pressure* — memfree's counterpart. Large swap used = need to free up.
# Per-app RSS aggregation groups helper processes under their app to spot reclaim candidates.
memcheck() {
  echo "── Pressure indicators (large swap used = need to free up) ──"
  sysctl vm.swapusage | sed 's/^vm.swapusage:/Swap: /'
  top -l 1 -s 0 | awk '/PhysMem/ {sub(/PhysMem:/,""); print "Phys: "$0}'
  echo
  echo "── Per-app aggregated memory top 12 (reclaim candidates) ──"
  ps axo rss,comm | awk 'NR>1 {sub(/.*\//,"",$2); m[$2]+=$1}
    END {for (a in m) printf "%7.0f MB  %s\n", m[a]/1024, a}' | sort -rn | head -12
}

# --- Claude process viewer (from msbaek/dotfiles) ---
# Groups running claude sessions (★ = current session, always protected).
#   ccps        inspect only (read-only, safe)
#   ccps -k     dry-run listing of stale cleanup candidates (never kills)
ccps() {
  local self=$$ sp=""
  while [ "$self" -gt 1 ]; do
    [ "$(ps -o comm= -p "$self" 2>/dev/null | sed 's#.*/##')" = claude ] && { sp=$self; break; }
    self=$(ps -o ppid= -p "$self" 2>/dev/null | tr -d ' '); [ -z "$self" ] && break
  done
  echo "   PID     GROUP        ELAPSED    RSS      TTY      (★=current session, protected)"
  ps -axo pid=,ppid=,tty=,etime=,rss=,comm= | awk -v sp="$sp" '
    {c=$NF; sub(/.*\//,"",c)}
    c=="claude" {
      grp = ($2==1) ? "orphan" : ($3=="??" ? "background" : "interactive")
      printf "%s %-7s %-12s %-10s %6.0fMB  %s\n", ($1==sp?"★":" "), $1, grp, $4, $5/1024, $3
    }' | sort -k2
  [ "$1" = "-k" ] && _cc_stale_review "$sp"
}

# TODO(human): decide which claude processes count as "stale" and print them dry-run.
#   $1 = current session PID (always protect, never a candidate).
#   Groups from ccps: interactive (open sessions) / background (MCP·headless) / orphan (PPID 1).
#   Your call: orphans only? long-etime background? an idle threshold?
#   Iterate claude rows via `ps -axo pid=,ppid=,etime=,comm=` and print
#   "would kill: <pid> (<group>, idle <etime>)" — output only, NEVER kill.
_cc_stale_review() {
  local keep="$1"
  : # TODO(human)
}

# --- Git repository health (from msbaek/dotfiles, https://news.hada.io/topic?id=28324) ---

# Top 20 most-changed files in the last year — change hotspots / bug-prone areas
git-churn() {
  git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
}

# Commits per contributor (merges excluded) — bus factor / knowledge silo check
git-contributors() {
  git shortlog -sn --no-merges
}

# Top 20 files most touched by fix/bug commits — fragile area detection
git-buggy-files() {
  git log -i -E --grep='\b(fix|fixed|fixes|bug|broken)\b' --name-only --format='' | sort | uniq -c | sort -nr | head -20
}

# Commits per month — development momentum trend
git-timeline() {
  git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
}

# revert/hotfix/emergency/rollback commits in the last year — release stability signal
git-hotfixes() {
  git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
}

# --- Claude Code dynamic MCP loading ---
export ENABLE_LSP_TOOLS=1
export ENABLE_TOOL_SEARCH=true

# --- SDKMAN (must be at the end) ---
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# --- NVM (lazy load — only loads when nvm/node/npm/npx is first used) ---
# Homebrew node stays on PATH regardless; this only defers nvm.sh sourcing.
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}
nvm()  { _load_nvm; nvm  "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm  "$@"; }
npx()  { _load_nvm; npx  "$@"; }

# --- pyenv ---
if command -v pyenv &>/dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
