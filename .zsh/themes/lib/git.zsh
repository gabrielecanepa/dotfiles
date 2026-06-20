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
ZSH_THEME_GIT_ICON_GITLAB="\\uf296"

typeset -g _GIT_BRANCH=${(g::)ZSH_THEME_GIT_ICON_BRANCH}
typeset -g _GIT_COMMIT=${(g::)ZSH_THEME_GIT_ICON_COMMIT}
typeset -g _GIT_GITHUB=${(g::)ZSH_THEME_GIT_ICON_GITHUB}
typeset -g _GIT_GITLAB=${(g::)ZSH_THEME_GIT_ICON_GITLAB}
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

_git_remote_icon() {
  emulate -L zsh
  local config=$_GIT_TOPLEVEL/.git/config
  [[ -r $config ]] || { : ${(P)1::=""}; return 0 }
  local line in_remote=0
  while IFS= read -r line; do
    case $line in
      '[remote '*) in_remote=1 ;;
      '['*) in_remote=0 ;;
      *)
        (( in_remote )) && [[ $line == *url\ =* ]] || continue
        case $line in
          *github*) : ${(P)1::=$_GIT_GITHUB}; return 0 ;;
          *gitlab*) : ${(P)1::="%F{202}${_GIT_GITLAB}%f"}; return 0 ;;
        esac
        ;;
    esac
  done < $config
  : ${(P)1::=""}
}

_git_segment() {
  emulate -L zsh
  _GIT_SEGMENT=""
  _git_in_repo || return 0
  git check-ignore . &>/dev/null && return 0

  local segment="%F{202}${_GIT_BRANCH}$(git_prompt_info)%f$(git_prompt_status)"
  local icon
  _git_remote_icon icon
  if [[ -n $icon ]]; then
    _GIT_SEGMENT="${icon}${_GIT_COMMIT}${segment} "
  else
    _GIT_SEGMENT="${segment} "
  fi
}
