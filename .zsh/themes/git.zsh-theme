# Status-colored prompt with the current directory and the shared git segment;
# the right prompt shows a dimmed lowercase date and time refreshed on every
# prompt. Git segment icons and flags follow ZSH_THEME_GIT_* from lib/git.zsh.

zmodload zsh/datetime
source ${0:A:h}/lib/hooks.zsh
source ${0:A:h}/lib/git.zsh
source ${0:A:h}/lib/title.zsh

typeset -g _GIT_RPROMPT=""

_git_rprompt() {
  emulate -L zsh
  strftime -s _GIT_RPROMPT '%a %-e %b %H:%M:%S' $EPOCHSECONDS
  _GIT_RPROMPT=${(L)_GIT_RPROMPT}
}

_theme_hook precmd _git_segment
_theme_hook precmd _git_rprompt

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} '
PROMPT+='%1~ '
PROMPT+='${_GIT_SEGMENT}'
RPROMPT='%F{244}${_GIT_RPROMPT}%f'
