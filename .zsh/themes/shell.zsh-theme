autoload -U add-zsh-hook

typeset -ga _THEME_HOOKS

() {
  emulate -L zsh
  local spec
  for spec in $_THEME_HOOKS; do
    add-zsh-hook -d ${spec%%:*} ${spec#*:}
  done
  _THEME_HOOKS=()
}

PROMPT='zsh-${ZSH_VERSION}$ '
RPROMPT=
