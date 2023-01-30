# Tabs
ZSH_THEME_TERM_TITLE_IDLE=""
ZSH_THEME_TERM_TAB_TITLE_IDLE=""

# Icons
icon="\\u"
icon_branch="${icon}e727"
icon_commit="${icon}e729"
icon_github="${icon}f7a3"
icon_node="${icon}e718"
icon_ruby="${icon}f43b"
icon_php="${icon}e608"
icon_python="${icon}f81f"

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
  git check-ignore . &>/dev/null && return 1 # return if in a parent .gitignore

  local git_prompt="%F{202}$icon_branch$(git_prompt_info)%{$reset_color%}$(git_prompt_status)"

  if git config --get remote.origin.url &>/dev/null; then
    echo "$icon_github$icon_commit$git_prompt "
  else
    echo "$git_prompt "
  fi
}

## Node.js
function node_prompt() {
  local node_version="$(node -v &>/dev/null && echo ${$(node -v)#v} || echo n/a)"
  echo "%{$fg[green]%}$icon_node $node_version%{$reset_color%}"
}

## Ruby
function ruby_prompt() {
  local ruby_version="$(ruby -v &>/dev/null && echo ${(M)$(ruby -v)##[0-9].[0-9].[0-9]} || echo n/a)"
  echo "%{$fg[red]%}$icon_ruby $ruby_version%{$reset_color%}"
}

## Python
function python_prompt() {
  local python_version="$(python3 -V &>/dev/null && echo ${$(python3 -V)#Python} || echo n/a)"
  echo "%{$fg[yellow]%}$icon_python $python_version%{$reset_color%}"
}

## PHP
function php_prompt() {
  local php_version="$(php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3)"
  echo "%{$fg[blue]%}$icon_php $php_version%{$reset_color%}"
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
    *) echo "${fg[red]}Unknown theme prompt: $rprompt";;
  esac
done

RPROMPT="${(j:  :)rprompts}"

# Cleanups
unset icon rprompt rprompts
