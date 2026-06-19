autoload -U add-zsh-hook

ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_UNSTAGED=""
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}*"
ZSH_THEME_GIT_ICON_BRANCH="\\ue727"
ZSH_THEME_GIT_ICON_COMMIT="\\ue729"
ZSH_THEME_GIT_ICON_GITHUB="\\uf09b"

typeset -g _GIT_BRANCH=${(g::)ZSH_THEME_GIT_ICON_BRANCH}
typeset -g _GIT_COMMIT=${(g::)ZSH_THEME_GIT_ICON_COMMIT}
typeset -g _GIT_GITHUB=${(g::)ZSH_THEME_GIT_ICON_GITHUB}
typeset -g _GIT_SEGMENT=""
typeset -g _GIT_TOPLEVEL=""

_git_in_repo() {
  emulate -L zsh
  local d=$PWD
  while [[ -n $d ]]; do
    if [[ -e $d/.git ]]; then
      _GIT_TOPLEVEL=$d
      return 0
    fi
    [[ $d == / ]] && break
    d=${d:h}
  done
  _GIT_TOPLEVEL=""
  return 1
}

_git_has_remote() {
  emulate -L zsh
  local config=$_GIT_TOPLEVEL/.git/config
  [[ -r $config ]] || return 1
  local line
  while IFS= read -r line; do
    [[ $line == '[remote '* ]] && return 0
  done < $config
  return 1
}

_git_segment() {
  emulate -L zsh
  _GIT_SEGMENT=""
  _git_in_repo || return 0
  git check-ignore . &>/dev/null && return 0

  local segment="%F{202}${_GIT_BRANCH}$(git_prompt_info)%f$(git_prompt_status)"
  if _git_has_remote; then
    _GIT_SEGMENT="${_GIT_GITHUB}${_GIT_COMMIT}${segment} "
  else
    _GIT_SEGMENT="${segment} "
  fi
}
