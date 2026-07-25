ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME=squanchy
ZSH_COMPLETIONS=(docker glab pnpm)
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
[[ -d ${ZSH_COMPDUMP:h} ]] || mkdir -p ${ZSH_COMPDUMP:h}
CASE_SENSITIVE=false
COMPLETION_WAITING_DOTS=false
DISABLE_AUTO_TITLE=true
DISABLE_LS_COLORS=false
DISABLE_UNTRACKED_FILES_DIRTY=false
ENABLE_CORRECTION=false
HIST_STAMPS="yyyy-mm-dd"
HYPHEN_INSENSITIVE=false

zstyle ':bracketed-paste-magic' active-widgets '.self-*'
zstyle ':completion:*' list-dirs-first true
zstyle ':omz:alpha:lib:git' async-prompt false
zstyle ':omz:update' frequency 7
zstyle ':omz:update' mode auto

zle_highlight+=(paste:none)

plugins=(
  colored-man-pages
  colorize
  gh
  git-auto-fetch
  gitfast
  nodenv
  npm
  pyenv
  rbenv
  themes
  zsh-autosuggestions
  zsh-claudecode-completion
  zsh-completions
  zsh-syntax-highlighting
  # Custom
  logger
  brewfile
  code-workspace
  colors256
  completions
  deps
  dotfiles
  filesystem
  gatekeeper
  google
  lts
  node
  npm-global
  plugin
  profile
)

. "$ZSH/oh-my-zsh.sh"

# Path, dotfiles, and aliases
initialize-path
dotfiles init
. "$HOME/.aliases"
