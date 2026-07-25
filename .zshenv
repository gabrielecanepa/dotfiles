typeset -aU path fpath manpath
typeset -T INFOPATH infopath
typeset -U infopath

export LANG="en_US.UTF-8"

# Homebrew
if [[ $CPUTYPE == arm64 ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
else
  export HOMEBREW_PREFIX="/usr/local"
fi
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
export HOMEBREW_BUNDLE_FILE="$HOME/.homebrew/Brewfile"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
infopath=("$HOMEBREW_PREFIX/share/info" $infopath)

# Version managers
export NODENV_ROOT="$HOME/.nodenv"
export NODENV_HOOK_PATH="$HOME/.config/nodenv/hooks"
export PYENV_ROOT="$HOME/.pyenv"
export RBENV_ROOT="$HOME/.rbenv"

# Package managers
export PNPM_HOME="$HOME/.pnpm/global"
export BUN_INSTALL="$HOME/.bun"

# Agents
export COPILOT_CUSTOM_INSTRUCTIONS_DIRS="$HOME/.agents"

initialize-path() {
  path=(
    "$HOME/.local/bin"
    "$NODENV_ROOT/shims" "$PYENV_ROOT/shims" "$RBENV_ROOT/shims"
    "$BUN_INSTALL/bin" "$PNPM_HOME"
    "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
    $path
  )
  manpath=("$HOMEBREW_PREFIX/share/man" $manpath)
}
initialize-path
