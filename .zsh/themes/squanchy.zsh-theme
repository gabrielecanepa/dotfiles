# ⚡️ Squanchy - https://github.com/gabrielecanepa/dotfiles

# Tabs
ZSH_THEME_TERM_TITLE_IDLE="%n@%m: %~"
ZSH_THEME_TERM_TAB_TITLE_IDLE="%~"

# Icons 
branch_icon="\\ue727" 
nvm_icon="\\ue718"

ruby_icon="\\uf43b"
python_icon="\\uf81f"
# php_icon="\\ue608"

# Set up prompts
# if [ ${#ZSH_THEME_PROMPTS[@]} -eq 0 ]; then
#   ZSH_THEME_PROMPTS=(git nvm ruby python php)
# fi

# Prompt
PROMPT=' %(?:%{$fg_bold[green]%}➜:%{$fg_bold[red]%}➜) ' # pre-prompt
PROMPT+='%{$fg[cyan]%}%c%{$reset_color%} ' # path
# if [[ ${ZSH_THEME_PROMPTS[(ie)git]} -le ${#ZSH_THEME_PROMPTS} ]]; then
  PROMPT+='$(git_prompt)' # git
# fi

# Post prompt
rprompts=()
# for prompt in $ZSH_THEME_PROMPTS; do
#   prompt_info="${prompt}_prompt_info"
#   type -a $prompt > /dev/null && rprompts+=('$($prompt_info)')
# done
type -a nvm > /dev/null && rprompts+=('$(nvm_prompt_info)') # nvm
type -a ruby > /dev/null && rprompts+=('$(ruby_prompt_info)') # ruby
type -a python > /dev/null && rprompts+=('$(python_prompt_info)') # python
# type -a php > /dev/null && rprompts+=('$(php_prompt_info)') # php
RPROMPT=${(j:  :)rprompts}
unset rprompts

# Git
ZSH_THEME_GIT_PROMPT_PREFIX="%F{202}$branch_icon"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}*"
ZSH_THEME_GIT_PROMPT_UNSTAGED=""
git_prompt() {
  # Hide branch if current path is in .gitignore
  if git check-ignore . &> /dev/null; then
    echo ""
  else
    echo "$(git_prompt_info)$(git_prompt_status) "
  fi
}

# nvm
ZSH_THEME_NVM_PROMPT_PREFIX="%{$fg[green]%}$nvm_icon "
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%}"

# Ruby
ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}$ruby_icon "
ZSH_THEME_RUBY_PROMPT_SUFFIX="%{$reset_color%}"

# Python
ZSH_THEME_PYTHON_PROMPT_PREFIX="%{$fg[yellow]%}$python_icon "
ZSH_THEME_PYTHON_PROMPT_SUFFIX="%{$reset_color%}"
python_version() { 
  python -V 2>&1 | sed 's/Python //'
}
python_prompt_info() { 
  echo "$ZSH_THEME_PYTHON_PROMPT_PREFIX$(python_version)$ZSH_THEME_PYTHON_PROMPT_SUFFIX" 
}

# PHP
# ZSH_THEME_PHP_PROMPT_PREFIX="%{$fg[blue]%}$php_icon "
# ZSH_THEME_PHP_PROMPT_SUFFIX="%{$reset_color%}"
# php_version() { 
#   php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3 
# }
# php_prompt_info() { 
#   echo "$ZSH_THEME_PHP_PROMPT_PREFIX$(php_version)$ZSH_THEME_PHP_PROMPT_SUFFIX" 
# }
