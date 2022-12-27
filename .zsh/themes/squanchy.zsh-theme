# Tabs
ZSH_THEME_TERM_TITLE_IDLE="%n@%m: %~"
ZSH_THEME_TERM_TAB_TITLE_IDLE="%~"

# Icons
local icon="\\u"
local icon_branch="${icon}e727"
local icon_commit="${icon}e729"
local icon_github="${icon}f7a3"
local icon_node="${icon}e718"
local icon_ruby="${icon}f43b"
local icon_php="${icon}e608"
local icon_python="${icon}f81f"

# Prompts

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

local function git_prompt() {
  # Hide branch if current path is specified in a parent gitignore
  git check-ignore . &>/dev/null && return 1

  local git_prompt="%F{202}$icon_branch$(git_prompt_info)$(git_prompt_status) "

  if git config --get remote.origin.url &>/dev/null; then
    echo "%{$reset_color%}$icon_github$icon_commit$git_prompt"
    return 0
  fi

  echo $git_prompt
}

## Node.js
ZSH_THEME_NODE_PROMPT_PREFIX="%{$fg[green]%}$icon_node "
ZSH_THEME_NODE_PROMPT_SUFFIX="%{$reset_color%}"

local function node_prompt() {
  local function version() {
    node -v &>/dev/null && node -v | sed "s/v//" || echo "⚠️"
  }

  echo "$ZSH_THEME_NODE_PROMPT_PREFIX$(version)$ZSH_THEME_NODE_PROMPT_SUFFIX"
}

## Ruby
ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}$icon_ruby "
ZSH_THEME_RUBY_PROMPT_SUFFIX="%{$reset_color%}"

local function ruby_prompt() {
  ruby_prompt_info &>/dev/null && echo "${$(ruby_prompt_info)//[\(\)]/}" || echo "⚠️"
}

## Python
ZSH_THEME_PYTHON_PROMPT_PREFIX="%{$fg[yellow]%}$icon_python "
ZSH_THEME_PYTHON_PROMPT_SUFFIX="%{$reset_color%}"

local function python_prompt() {
  local function version() {
    type -a python &>/dev/null && python -V | sed "s/Python //" || echo "⚠️"
  }

  echo "$ZSH_THEME_PYTHON_PROMPT_PREFIX$(version)$ZSH_THEME_PYTHON_PROMPT_SUFFIX"
}

## PHP
# ZSH_THEME_PHP_PROMPT_PREFIX="%{$fg[blue]%}$icon_php "
# ZSH_THEME_PHP_PROMPT_SUFFIX="%{$reset_color%}"

# function php_version() {
#   php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3
# }
# function php_prompt() {
#   echo "$ZSH_THEME_PHP_PROMPT_PREFIX$(php_version)$ZSH_THEME_PHP_PROMPT_SUFFIX"
# }

# Prompt
PROMPT='%(?:%{$fg_bold[green]%}➜:%{$fg_bold[red]%}➜) %{$fg[cyan]%}%c ' # pre-prompt and path
PROMPT+='$(git_prompt)' # git

# Right prompt
local rprompts=()
for rprompt in $ZSH_THEME_RPROMPTS; do
  local function rprompt_fn() { echo "$(${rprompt}_prompt)" }
  rprompts+="$(rprompt_fn)"
done
unset rprompt

RPROMPT="${(j:  :)rprompts}"
