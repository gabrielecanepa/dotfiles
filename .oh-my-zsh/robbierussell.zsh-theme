# robbierussell - works with https://www.nerdfonts.com

PROMPT="%(?:%{$fg_bold[green]%}➜:%{$fg_bold[red]%}➜)" # pre prompt
PROMPT+=' %{$fg[cyan]%}%c%{$reset_color%}$(git_prompt_info) ' # path + git
RPROMPT='$(ruby_prompt)$(nvm_prompt_info)' # ruby + nvm

# git
ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg_bold[blue]%}$(echo \\ue727)"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# ruby
local ruby_prompt () {
  echo "%{$fg[red]%}$(echo \\uf43b) $(ruby_prompt_info)%{$reset_color%}  "
}

# nvm
ZSH_THEME_NVM_PROMPT_PREFIX="%{$fg[green]%}$(echo \\ue718) "
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%}\n"
