export FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:${FPATH}"
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

# Oh My Zsh (https://ohmyz.sh)
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME=shell
ZSH_THEME_RPROMPTS=(node ruby python)
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
[[ -d ${ZSH_COMPDUMP:h} ]] || mkdir -p ${ZSH_COMPDUMP:h}
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
  deps
  gatekeeper
  google
  lts
  node-version
  npm-global
  path
  plugin
  pnpm-completions
  profile
)

fpath=($ZSH_CUSTOM/completions $HOME/.docker/completions $fpath)

. "$ZSH/oh-my-zsh.sh"
_init_path

# Git (https://git-scm.com)
if profile check; then
  [[ "$(git config --file $HOME/.gitprofile user.name 2>/dev/null)" != "$NAME" ]] && git config --file $HOME/.gitprofile user.name "$NAME"
  [[ "$(git config --file $HOME/.gitprofile user.email 2>/dev/null)" != "$EMAIL" ]] && git config --file $HOME/.gitprofile user.email "$EMAIL"
  [[ "$(git config --file $HOME/.gitprofile core.editor 2>/dev/null)" != "$GIT_EDITOR" ]] && git config --file $HOME/.gitprofile core.editor "$GIT_EDITOR"
  for file in $HOME/.husky/*; do
    [[ -d "$file" ]] && continue
    hook="$HOME/.git/hooks/$(basename $file)"
    [[ "$(readlink "$hook")" == "$file" ]] && continue
    rm -f "$hook" && ln -s "$file" "$hook"
  done
fi

# Completions
for comp in docker npm; do [[ -e $ZSH_CUSTOM/completions/_$comp ]] || completions $comp; done
( [[ -s "$ZSH_COMPDUMP" && ( ! -s "$ZSH_COMPDUMP.zwc" || "$ZSH_COMPDUMP" -nt "$ZSH_COMPDUMP.zwc" ) ]] && zcompile "$ZSH_COMPDUMP" ) &!

# Aliases
. $HOME/.aliases
autoload -Uz add-zsh-hook
add-zsh-hook precmd _git_aliases
