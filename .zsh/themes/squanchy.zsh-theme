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
  # use different color for dotfiles repository
  [[ "$(git_prompt)" =~ "dotfiles(\|.+)?" ]] && echo "%{$fg[blue]%}" || echo "%F{202}"
}
git_prompt()
{
  # Hide branch if current path is in a parent .gitignore
  if git check-ignore . &> /dev/null; then
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

## Ruby
ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}$icon_ruby "
ZSH_THEME_RUBY_PROMPT_SUFFIX="%{$reset_color%}"

## Python
ZSH_THEME_PYTHON_PROMPT_PREFIX="%{$fg[yellow]%}$icon_python "
ZSH_THEME_PYTHON_PROMPT_SUFFIX="%{$reset_color%}"

python_version()
{
  python -V 2>&1 | sed 's/Python //'
}
python_prompt_info()
{
  echo "$ZSH_THEME_PYTHON_PROMPT_PREFIX$(python_version)$ZSH_THEME_PYTHON_PROMPT_SUFFIX"
}

## PHP
ZSH_THEME_PHP_PROMPT_PREFIX="%{$fg[blue]%}$icon_php "
ZSH_THEME_PHP_PROMPT_SUFFIX="%{$reset_color%}"

php_version()
{
  php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3
}
php_prompt_info()
{
  echo "$ZSH_THEME_PHP_PROMPT_PREFIX$(php_version)$ZSH_THEME_PHP_PROMPT_SUFFIX"
}

# Prompt display
PROMPT='%(?:%{$fg_bold[green]%}➜:%{$fg_bold[red]%}➜)' # pre-prompt arrow
PROMPT+=' %{$fg[cyan]%}%c' # path
PROMPT+=' $(git_branch_color)$(git_prompt)' # git

# Post prompt display
rprompts=()

if [ ${#ZSH_THEME_RPROMPTS[@]} -eq 0 ]; then
  ZSH_THEME_RPROMPTS=(nvm ruby python php)
fi

for rprompt in $ZSH_THEME_RPROMPTS; do
  rprompt_info="${rprompt}_prompt_info"
  type -a $rprompt >/dev/null && rprompts+=("$(eval $rprompt_info)")
done

RPROMPT=${(j:  :)rprompts}

unset icon_branch icon_node icon_ruby icon_php icon_python rprompts rprompt rprompt_info
