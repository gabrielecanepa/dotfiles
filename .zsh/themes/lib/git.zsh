# Shared git prompt segment: remote icon, branch, and status flags parsed from
# a single `git status --porcelain -b` call per prompt.

autoload -U colors && colors

ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}*"
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

_git_dir() {
  emulate -L zsh
  local dir=$_GIT_TOPLEVEL/.git line
  if [[ -f $dir && -r $dir ]]; then
    read -r line < $dir
    dir=${line#gitdir: }
    [[ $dir != /* ]] && dir=$_GIT_TOPLEVEL/$dir
    if [[ -r $dir/commondir ]]; then
      read -r line < $dir/commondir
      [[ $line != /* ]] && line=$dir/$line
      dir=$line
    fi
  fi
  : ${(P)1::=$dir}
}

_git_remote_icon() {
  emulate -L zsh
  local gitdir
  _git_dir gitdir
  local config=$gitdir/config
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
          *gitlab*) : ${(P)1::="%F{209}${_GIT_GITLAB}%f"}; return 0 ;;
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
  command git check-ignore -q . 2>/dev/null && return 0

  local -a lines
  lines=(${(f)"$(command git status --porcelain -b 2>/dev/null)"})
  (( ${#lines} )) || return 0

  local header=${lines[1]} ref
  if [[ $header == '## No commits yet on '* ]]; then
    ref=${header#'## No commits yet on '}
  elif [[ $header == '## HEAD (no branch)' ]]; then
    ref=$(command git rev-parse --short HEAD 2>/dev/null)
    ref=${ref:-HEAD}
  else
    ref=${${header#'## '}%%...*}
  fi
  ref=${ref//\%/%%}

  local untracked="" modified="" deleted="" line x y
  for line in ${lines[2,-1]}; do
    x=${line[1]} y=${line[2]}
    if [[ $line == '??'* ]]; then
      untracked=$ZSH_THEME_GIT_PROMPT_UNTRACKED
    elif [[ $x == D || $y == D ]]; then
      deleted=$ZSH_THEME_GIT_PROMPT_DELETED
    elif [[ $x == M || $y == (M|T) ]]; then
      modified=$ZSH_THEME_GIT_PROMPT_MODIFIED
    fi
    [[ -n $untracked && -n $modified && -n $deleted ]] && break
  done

  local flags=""
  [[ $header == *'[behind '* || $header == *', behind '* ]] && flags+=$ZSH_THEME_GIT_PROMPT_BEHIND
  [[ $header == *'[ahead '* ]] && flags+=$ZSH_THEME_GIT_PROMPT_AHEAD
  flags+="${deleted}${modified}${untracked}"
  [[ -n $flags ]] && flags+="%{$reset_color%}"

  local segment="%F{209}${_GIT_BRANCH}${ref}%f${flags}"
  local icon
  _git_remote_icon icon
  if [[ -n $icon ]]; then
    _GIT_SEGMENT="${icon}${_GIT_COMMIT}${segment} "
  else
    _GIT_SEGMENT="${segment} "
  fi
}
