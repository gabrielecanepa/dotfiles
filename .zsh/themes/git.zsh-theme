zmodload zsh/datetime
source ${0:A:h}/lib/git.zsh
source ${0:A:h}/lib/title.zsh

typeset -g _GIT_RPROMPT=""

_git_rprompt() {
  emulate -L zsh
  strftime -s _GIT_RPROMPT '%a %-e %b %H:%M:%S' $EPOCHSECONDS
  _GIT_RPROMPT=${(L)_GIT_RPROMPT}
}

add-zsh-hook precmd _git_segment
add-zsh-hook precmd _git_rprompt

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} '
PROMPT+='%1~ '
PROMPT+='${_GIT_SEGMENT}'
RPROMPT='%F{244}${_GIT_RPROMPT}%f'
