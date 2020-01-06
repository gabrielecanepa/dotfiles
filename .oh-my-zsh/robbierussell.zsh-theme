# robbierussell theme - works with https://www.nerdfonts.com

PROMPT="%(?:%{$fg_bold[green]%}➜:%{$fg_bold[red]%}➜)" # pre prompt
PROMPT+=' %{$fg[cyan]%}%~%{$reset_color%}$(robbierussell_git_prompt) ' # path + git
RPROMPT='$(robbierussell_ruby_prompt)$(nvm_prompt_info)' # ruby + nvm

# git
ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg_bold[blue]%}$(echo \\ue727)"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}*"
ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}*"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"

local robbierussell_git_branch () {
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

local robbierussell_git_status() {
  _status=""

  _index=$(command git status --short 2> /dev/null) # local
  if [[ -n "$_index" ]]; then
    if $(echo "$_index" | command grep -q '^.[MT] '); then
      _status="$_status$ZSH_THEME_GIT_PROMPT_UNSTAGED"
    fi
    if $(echo "$_index" | command grep -q -E '^\?\? '); then
      _status="$_status$ZSH_THEME_GIT_PROMPT_UNTRACKED"
    fi
    if $(echo "$_index" | command grep -q '^.[D] '); then
      _status="$_status$ZSH_THEME_GIT_PROMPT_DELETED"
    fi
  fi

  _index=$(command git status --porcelain -b 2> /dev/null) # remote
  if [[ -n "$_index" ]]; then
    # _status="$_status "
    if $(echo "$_index" | command grep -q '^## .*ahead'); then
      _status="$_status$ZSH_THEME_GIT_PROMPT_AHEAD"
    fi
    if $(echo "$_index" | command grep -q '^## .*behind'); then
      _status="$_status$ZSH_THEME_GIT_PROMPT_BEHIND"
    fi
  fi


  echo $_status
}

local robbierussell_git_prompt () {
  local _branch=$(robbierussell_git_branch)
  local _status=$(robbierussell_git_status)
  local _result=""

  if [[ "${_branch}x" != "x" ]]; then
    _result="$ZSH_THEME_GIT_PROMPT_PREFIX$_branch"
    if [[ "${_status}x" != "x" ]]; then
      _result="$_result$_status"
    fi
    _result="$_result$ZSH_THEME_GIT_PROMPT_SUFFIX"
  fi

  echo $_result
}

# ruby
local robbierussell_ruby_prompt () {
  echo "%{$fg[red]%}$(echo \\uf43b) $(ruby_prompt_info)%{$reset_color%}  "
}

# nvm
ZSH_THEME_NVM_PROMPT_PREFIX="%{$fg[green]%}$(echo \\ue718) "
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%}"
