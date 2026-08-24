# Theme hooks: sourcing unregisters the previous theme's hooks so the
# oh-my-zsh `theme` command switches cleanly in a live shell. Themes
# register their own hooks with _theme_hook.

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

_theme_hook() {
  emulate -L zsh
  add-zsh-hook $1 $2
  _THEME_HOOKS+="$1:$2"
}
