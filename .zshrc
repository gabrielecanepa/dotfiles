typeset -aU fpath
fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

ZSH=~/.oh-my-zsh
ZSH_CUSTOM=~/.zsh
ZSH_THEME=squanchy
ZSH_COMPDUMP=${XDG_CACHE_HOME:-~/.cache}/zsh/zcompdump-$ZSH_VERSION
[[ -d ${ZSH_COMPDUMP:h} ]] || mkdir -p ${ZSH_COMPDUMP:h}

HIST_STAMPS=yyyy-mm-dd
zle_highlight+=(paste:none)
zstyle ':bracketed-paste-magic' active-widgets '.self-*'
zstyle ':completion:*' list-dirs-first true
zstyle ':omz:alpha:lib:git' async-prompt false
zstyle ':omz:update' frequency 7
zstyle ':omz:update' mode auto

plugins=(
  colored-man-pages
  colorize
  git-auto-fetch
  gitfast
  themes
  # Custom
  brewfile
  code-workspace
  completions
  defaults
  filesystem
  git-shortcuts
  google
  launchd
  lts
  node-modules-bin
  node-version
  npm-global
  plugin
  quarantine
  # From zsh-users
  zsh-autosuggestions
  zsh-syntax-highlighting
)

completions=(
  codex
  docker
  gh
  glab
  mole
  op
  orb
  pnpm
  tailscale
)

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

source $ZSH/oh-my-zsh.sh
