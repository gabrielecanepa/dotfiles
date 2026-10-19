export LANG=en_US.UTF-8

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code --wait --reuse-window'
fi

if [[ $CPUTYPE == arm64 ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
else
  export HOMEBREW_PREFIX=/usr/local
fi
export HOMEBREW_NO_ENV_HINTS=1

export PNPM_HOME=~/.pnpm
