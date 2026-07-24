# Terminal tab and window titles from precmd, preexec, and chpwd.

autoload -U add-zsh-hook
(( $+functions[_theme_hook] )) || _theme_hook() { add-zsh-hook "$@" }

_title_emit() {
  emulate -L zsh
  print -rn -- $'\e]1;'"$1"$'\a'
  print -rn -- $'\e]2;'"$1"$'\a'
}

_title_precmd() {
  emulate -L zsh
  _title_emit "${(%):-%1~}"
}

_title_preexec() {
  emulate -L zsh
  _title_emit "${(%):-%1~}: $2"
}

_title_chpwd() {
  emulate -L zsh
  _title_emit "${(%):-%1~}"
}

_theme_hook precmd _title_precmd
_theme_hook preexec _title_preexec
_theme_hook chpwd _title_chpwd
