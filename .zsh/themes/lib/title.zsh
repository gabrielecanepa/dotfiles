autoload -U add-zsh-hook

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

add-zsh-hook precmd _title_precmd
add-zsh-hook preexec _title_preexec
add-zsh-hook chpwd _title_chpwd
