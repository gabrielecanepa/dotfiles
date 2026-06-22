typeset -aU path fpath

export LANG="en_US.UTF-8"

# Homebrew (https://brew.sh)
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
export HOMEBREW_BUNDLE_FILE="$HOME/.homebrew/Brewfile"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# Version managers (https://github.com/{nodenv,pyenv,rbenv})
export NODENV_ROOT="$HOME/.nodenv"
export NODENV_HOOK_PATH="$HOME/.config/nodenv/hooks"
export PYENV_ROOT="$HOME/.pyenv"
export RBENV_ROOT="$HOME/.rbenv"

# Package managers (https://pnpm.io, https://bun.sh)
export PNPM_HOME="$HOME/.pnpm/global"
export BUN_INSTALL="$HOME/.bun"

# Agents (https://github.com/copilot)
export COPILOT_CUSTOM_INSTRUCTIONS_DIRS="$HOME/.agents"

initialize_path() {
  path=(
    "$NODENV_ROOT/shims" "$PYENV_ROOT/shims" "$RBENV_ROOT/shims"
    "$BUN_INSTALL/bin" "$PNPM_HOME"
    "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
    $path
  )
}
initialize_path
