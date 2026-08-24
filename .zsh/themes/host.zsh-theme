# Plain user@host prompt with exit status colors and the current directory.

autoload -U colors && colors
source ${0:A:h}/lib/hooks.zsh

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} %n@%m %1~ %# '
RPROMPT=
