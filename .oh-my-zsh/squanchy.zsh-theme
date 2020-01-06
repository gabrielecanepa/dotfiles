# squanchy.min theme - works with https://www.nerdfonts.com

PROMPT="%{$fg_bold[cyan]%}$(echo \\uf751) %c%{$reset_color%} " # path
PROMPT+='$(git_prompt_info)' # git
PROMPT+=" %(?:%{$fg[green]%}$:%{$fg[red]%}$) " # symbol
RPROMPT='$(ruby_prompt)$(nvm_prompt_info)' # ruby + nvm

# git
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}$(echo \\ue725) "
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "

# ruby
local ruby_prompt () {
  echo "%{$fg[red]%}$(echo \\uf43b) $(ruby_prompt_info)%{$reset_color%}  "
}

# nvm
ZSH_THEME_NVM_PROMPT_PREFIX="%{$fg[green]%}$(echo \\ue718) "
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%}\n"
