# ⚡️ Squanchy - https://github.com/gabrielecanepa/zsh-custom/blob/master/themes

# Tabs
ZSH_THEME_TERM_TITLE_IDLE="%n@%m: %~"
ZSH_THEME_TERM_TAB_TITLE_IDLE="%~"

# Icons
git_icon="\\ue727"
ruby_icon="\\uf43b"
nvm_icon="\\ue718"
php_icon="\\ue608"
python_icon="\\uf81f"

# Prompt
PROMPT=' %(?:%{$fg_bold[green]%}➜:%{$fg_bold[red]%}➜) ' # pre-prompt
PROMPT+='%{$fg[cyan]%}%c%{$reset_color%}' # path
PROMPT+='$(git_prompt_info)$(git_prompt_status) ' # git

RPROMPT='$(nvm_prompt_info)  $(ruby_prompt_info)' # languages

# Git
ZSH_THEME_GIT_PROMPT_PREFIX=" %F{202}$git_icon"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}*"
ZSH_THEME_GIT_PROMPT_UNSTAGED=""

# Ruby
ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}$ruby_icon "
ZSH_THEME_RUBY_PROMPT_SUFFIX="%{$reset_color%}"

# NVM
ZSH_THEME_NVM_PROMPT_PREFIX="%{$fg[green]%}$nvm_icon "
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%}"

# PHP
ZSH_THEME_PHP_PROMPT_PREFIX="%{$fg[blue]%}$php_icon "
ZSH_THEME_PHP_PROMPT_SUFFIX="%{$reset_color%}"
php_version() { 
  php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3 
}
php_prompt_info() { 
  echo "$ZSH_THEME_PHP_PROMPT_PREFIX$(php_version)$ZSH_THEME_PHP_PROMPT_SUFFIX" 
}

# Python
ZSH_THEME_PYTHON_PROMPT_PREFIX="%{$fg[yellow]%}$python_icon "
ZSH_THEME_PYTHON_PROMPT_SUFFIX="%{$reset_color%}"
python_version() { 
  python -V | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3 
}
python_prompt_info() { 
  echo "$ZSH_THEME_PYTHON_PROMPT_PREFIX$(python_version)$ZSH_THEME_PYTHON_PROMPT_SUFFIX" 
}
