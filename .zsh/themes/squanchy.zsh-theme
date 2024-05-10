# ⚡️ Zsh Theme Squanchy ⚡️ - https://github.com/gabrielecanepa/dotfiles

# Tabs
ZSH_THEME_TERM_TITLE_IDLE="%n@%m: %~"
ZSH_THEME_TERM_TAB_TITLE_IDLE="%~"

# Icons
icon_branch="\\ue727"
icon_node="\\ue718"
icon_ruby="\\uf43b"
icon_php="\\ue608"
icon_python="\\uf81f"

# Prompts

## Git
git_branch_color() {
  # return an empty string if not a git repo
  if ! git branch &>/dev/null; then
    echo ""
  # use a different color for the dotfiles branch
  elif [[ "$(git branch --show-current)" =~ "dotfiles" ]]; then
    echo "%{$fg[blue]%}"
  else
    echo "%F{202}"
  fi
}
git_prompt() {
  # hide branch if current path is specified in a parent .gitignore
  if git check-ignore . &>/dev/null; then
    echo ""
  else
    echo "$(git_prompt_info)$(git_prompt_status) "
  fi
}

ZSH_THEME_GIT_PROMPT_PREFIX="$icon_branch"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}*"
ZSH_THEME_GIT_PROMPT_UNSTAGED=""

## nvm
ZSH_THEME_NVM_PROMPT_PREFIX="%{$fg[green]%}$icon_node "
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%}"

nvm_prompt_info() {
  echo "$ZSH_THEME_NVM_PROMPT_PREFIX$(nvm current | sed 's/v//g')$ZSH_THEME_NVM_PROMPT_SUFFIX"
}

## Ruby
ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}$icon_ruby "
ZSH_THEME_RUBY_PROMPT_SUFFIX="%{$reset_color%}"

ruby_prompt_info() {
  echo "$ZSH_THEME_RUBY_PROMPT_PREFIX$(rbenv version-name)$ZSH_THEME_RUBY_PROMPT_SUFFIX"
}

## Python
ZSH_THEME_PYTHON_PROMPT_PREFIX="%{$fg[yellow]%}$icon_python "
ZSH_THEME_PYTHON_PROMPT_SUFFIX="%{$reset_color%}"

python_version() {
  python -V 2>&1 | sed 's/Python //'
}
python_prompt_info() {
  echo "$ZSH_THEME_PYTHON_PROMPT_PREFIX$(python_version)$ZSH_THEME_PYTHON_PROMPT_SUFFIX"
}

## PHP
ZSH_THEME_PHP_PROMPT_PREFIX="%{$fg[blue]%}$icon_php "
ZSH_THEME_PHP_PROMPT_SUFFIX="%{$reset_color%}"

php_version() {
  php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3
}
php_prompt_info() {
  echo "$ZSH_THEME_PHP_PROMPT_PREFIX$(php_version)$ZSH_THEME_PHP_PROMPT_SUFFIX"
}

# Prompt display
PROMPT='%(?:%{$fg_bold[green]%}➜:%{$fg_bold[red]%}➜)' # pre-prompt arrow
PROMPT+=' %{$fg[cyan]%}%c' # path
PROMPT+=' $(git_branch_color)$(git_prompt)' # git

# Post-prompt display
RPROMPT='$(
  rprompts=()
  for rprompt in $ZSH_THEME_RPROMPTS; do # $ZSH_THEME_RPROMPTS
    type -a $rprompt >/dev/null && rprompts+="$(${rprompt}_prompt_info)"
  done
  echo ${(j:  :)rprompts}
)'

unset icon_branch icon_node icon_ruby icon_php icon_python rprompts rprompt
