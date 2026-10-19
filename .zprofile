typeset -U path
typeset -TUx INFOPATH infopath

infopath=($HOMEBREW_PREFIX/share/info $infopath)

path=(
  ${NODENV_ROOT:-~/.nodenv}/shims
  ${PYENV_ROOT:-~/.pyenv}/shims
  ${RBENV_ROOT:-~/.rbenv}/shims
  ${BUN_INSTALL:+$BUN_INSTALL/bin}
  $PNPM_HOME/bin
  $HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin
  ~/.local/bin
  $path
)

export PATH
