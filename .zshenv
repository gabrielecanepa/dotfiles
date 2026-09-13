typeset -aU path fpath
typeset -T INFOPATH infopath
typeset -U infopath

export LANG="en_US.UTF-8"

# Homebrew
if [[ $CPUTYPE == arm64 ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
else
  export HOMEBREW_PREFIX="/usr/local"
fi
export HOMEBREW_BUNDLE_FILE="$HOME/.homebrew/Brewfile"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
infopath=("$HOMEBREW_PREFIX/share/info" $infopath)

# Package managers
export PNPM_HOME="$HOME/.pnpm"

# Containers
[[ -S "$HOME/.orbstack/run/docker.sock" ]] && export DOCKER_HOST="unix://$HOME/.orbstack/run/docker.sock"

# Agents
export COPILOT_CUSTOM_INSTRUCTIONS_DIRS="$HOME/.agents"

initialize-path() {
  path=(
    "$HOME/.nodenv/shims" "$HOME/.pyenv/shims" "$HOME/.rbenv/shims"
    "$BUN_INSTALL/bin" "$PNPM_HOME/bin"
    "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
    $path
  )
}
initialize-path
