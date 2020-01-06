# robbierussell.min theme - works with https://www.nerdfonts.com

PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )" # pre prompt
PROMPT+=' %{$fg[cyan]%}%~%{$reset_color%}$(git_prompt_info) ' # path + git
RPROMPT=""

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg_bold[blue]%}$(echo \\uf419)"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_CLEAN=""
