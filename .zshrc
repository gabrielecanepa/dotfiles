# Clear screen on startup
clear

export LANG="en_US.UTF-8"
export PATH="./bin:./.bin:$PATH"

# Homebrew (https://brew.sh)
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
export HOMEBREW_NO_INSTALL_FROM_API=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH+:$PATH}"
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}" 
export FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# Node.js (https://nodejs.org)
export PATH="./node_modules/.bin:$PATH"
export PNPM_HOME="$HOME/.pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Version managers
# nodenv (https://github.com/nodenv/nodenv)
# pyenv (https://github.com/pyenv/pyenv)
# rbenv (https://github.com/rbenv/rbenv)
for vm in nodenv pyenv rbenv; do
  export ${vm:u}_ROOT="$HOME/.${vm}"
  export PATH="$(eval "echo $"${vm:u}_ROOT"")/bin:$PATH"
  eval "$(${vm} init --path - zsh)"
done; unset vm

# Oh My Zsh (https://ohmyz.sh)
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
# ZSH_THEME="squanchy"
ZSH_THEME_RPROMPTS=(node ruby python)
ZSH_COMPDUMP="$HOME/.zcompdump"
ZSH_COMPLETIONS=(docker npm pnpm supabase)
ZSH_COMPLETIONS_PATH="$ZSH_CUSTOM/completions"

# Options
CASE_SENSITIVE=0
COMPLETION_WAITING_DOTS=""
DISABLE_AUTO_TITLE=0
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

# Plugins
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
  # From zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  # Custom
  brewfile
  colors256
  completions
  dependencies
  gatekeeper
  gemfile
  google
  lts
  node-version
  npm-global
  path
  plugin
  pnpm-completions
  profile
  themes
  vscode
)

. "$ZSH/oh-my-zsh.sh"

# Profile
if profile check; then
  # Git (https://git-scm.com)
  git config --file "$HOME/.gitprofile" user.name "$NAME"
  git config --file "$HOME/.gitprofile" user.email "$EMAIL"
  git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"
fi

# Completions
completions $ZSH_COMPLETIONS
fpath=($ZSH_COMPLETIONS_PATH $fpath)
autoload -Uz compinit
compinit

# Aliases
. "$HOME/.aliases"

# Avoid duplicates in path
typeset -aU path
