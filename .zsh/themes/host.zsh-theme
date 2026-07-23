# Plain user@host prompt with exit-status color and the current directory, no
# right prompt; sourcing it clears the previous theme's hooks.

autoload -U colors && colors
source ${0:A:h}/lib/hooks.zsh

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} %n@%m %1~ %# '
RPROMPT=
