export FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:${FPATH}"
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

# Oh My Zsh
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME=node
ZSH_THEME_SQUANCHY_RPROMPTS=(node python)
ZSH_COMPLETIONS=(docker glab npm pnpm)
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
[[ -d ${ZSH_COMPDUMP:h} ]] || mkdir -p ${ZSH_COMPDUMP:h}
CASE_SENSITIVE=0
COMPLETION_WAITING_DOTS=""
DISABLE_AUTO_TITLE=true
DISABLE_AUTO_UPDATE=1
DISABLE_LS_COLORS=0
DISABLE_UNTRACKED_FILES_DIRTY=0
ENABLE_CORRECTION=0
HIST_STAMPS="yyyy-mm-dd"
HYPHEN_INSENSITIVE=0
UPDATE_ZSH_DAYS=7
zstyle ':bracketed-paste-magic' active-widgets '.self-*'
zstyle ':completion:*' list-dirs-first true
zstyle ':omz:alpha:lib:git' async-prompt false
zstyle ':omz:update' mode auto
zle_highlight+=(paste:none)

plugins=(
  colored-man-pages
  colorize
  gh
  git-auto-fetch
  gitfast
  last-working-dir
  nodenv
  npm
  pyenv
  rbenv
  themes
  # From zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  # Custom
  brewfile
  colors256
  completions
  deps
  dotfiles
  gatekeeper
  google
  local-bin
  lts
  node-version
  path
  plugin
  profile
)

. "$ZSH/oh-my-zsh.sh"

# Path
initialize_path
unset -f initialize_path

# Dotfiles
dotfiles init

# Aliases
. $HOME/.aliases
autoload -Uz add-zsh-hook
add-zsh-hook precmd _git_aliases
