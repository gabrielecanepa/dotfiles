# Icons
ZSH_THEME_ICON_BRANCH="\\ue727"
ZSH_THEME_ICON_COMMIT="\\ue729"
ZSH_THEME_ICON_GITHUB="\\uf7a3"
ZSH_THEME_ICON_NODE="\\ue718"
ZSH_THEME_ICON_RUBY="\\uf43b"
ZSH_THEME_ICON_PHP="\\ue608"
ZSH_THEME_ICON_PYTHON="\\uf81f"

# Prompt

## Git
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}*"
ZSH_THEME_GIT_PROMPT_UNSTAGED=""

function git_prompt() {
  # Return if the current path is not in a Git repository or is specified in a parent .gitignore
  ! git rev-parse --is-inside-work-tree &>/dev/null || git check-ignore . &>/dev/null && echo "" && return 0

  local git_prompt="%F{202}$ZSH_THEME_ICON_BRANCH$(git_prompt_info)%{$reset_color%}$(git_prompt_status)"

  if git config --get remote.origin.url &>/dev/null; then
    echo "$ZSH_THEME_ICON_GITHUB$ZSH_THEME_ICON_COMMIT$git_prompt "
  else
    echo "$git_prompt "
  fi
}

## Node.js
function node_prompt() {
  local node_version="$(node -v &>/dev/null && echo ${$(node -v)#v} || echo n/a)"
  echo "%{$fg[green]%}$ZSH_THEME_ICON_NODE $node_version%{$reset_color%}"
}

## Ruby
function ruby_prompt() {
  local ruby_version="$(ruby -v &>/dev/null && echo ${(M)$(ruby -v)##[0-9].[0-9].[0-9]} || echo n/a)"
  echo "%{$fg[red]%}$ZSH_THEME_ICON_RUBY $ruby_version%{$reset_color%}"
}

## Python
function python_prompt() {
  local python_version="$(python3 -V &>/dev/null && echo ${$(python3 -V)#Python} || echo n/a)"
  echo "%{$fg[yellow]%}$ZSH_THEME_ICON_PYTHON $python_version%{$reset_color%}"
}

## PHP
function php_prompt() {
  local php_version="$(php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3)"
  echo "%{$fg[blue]%}$ZSH_THEME_ICON_PHP $php_version%{$reset_color%}"
}

PROMPT='%(?:%{$fg_bold[green]%}✓:%{$fg_bold[red]%}✗)%{$reset_color%} ' # status
PROMPT+='%{$fg[cyan]%}%c%{$reset_color%} ' # current path
PROMPT+='$(git_prompt)' # git

# Right prompt
rprompts=()

for rprompt in $(tr ' ' '\n' <<< "${ZSH_THEME_RPROMPTS[@]}" | awk '!u[$0]++' | tr '\n' ' '); do
  case $rprompt in
    node) rprompts+='$(node_prompt)';;
    ruby) rprompts+='$(ruby_prompt)';;
    python) rprompts+='$(python_prompt)';;
    php) rprompts+='$(php_prompt)';;
    *) echo "${fg[red]}Unknown theme prompt: $rprompt$reset_color";;
  esac
done

RPROMPT="${(j:  :)rprompts}"

# Cleanups
unset rprompt rprompts
