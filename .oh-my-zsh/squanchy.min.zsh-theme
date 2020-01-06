# squanchy theme - works with https://www.nerdfonts.com

PROMPT="%{$fg_bold[cyan]%}$(echo \\uf751) %~%{$reset_color%} " # path
PROMPT+='$(git_prompt_info)' # git
PROMPT+=" %(?:%{$fg[green]%}$:%{$fg[red]%}$) " # symbol
RPROMPT=""

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}$(echo \\ue725) "
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
