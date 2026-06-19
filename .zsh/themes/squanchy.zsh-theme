autoload -U colors && colors
autoload -U add-zsh-hook
zmodload zsh/datetime
zmodload -F zsh/stat b:zstat
source ${0:A:h}/lib/git.zsh
source ${0:A:h}/lib/title.zsh

ZSH_THEME_SQUANCHY_RPROMPT_EMPTY="n/a"
ZSH_THEME_SQUANCHY_ICON_NODE="\\ue718"
ZSH_THEME_SQUANCHY_ICON_PHP="\\ue608"
ZSH_THEME_SQUANCHY_ICON_PYTHON="\\ue606"
ZSH_THEME_SQUANCHY_ICON_RUBY="\\ueb48"
ZSH_THEME_SQUANCHY_ICON_UP="↑"
ZSH_THEME_SQUANCHY_ICON_PIN="⚑"
ZSH_THEME_SQUANCHY_ICON_PIN_ALT="⚐"

[[ -z "$ZSH_THEME_RPROMPTS" ]] && ZSH_THEME_RPROMPTS=(node ruby python php)

typeset -g _SQUANCHY_NODE=${(g::)ZSH_THEME_SQUANCHY_ICON_NODE}
typeset -g _SQUANCHY_PHP=${(g::)ZSH_THEME_SQUANCHY_ICON_PHP}
typeset -g _SQUANCHY_PYTHON=${(g::)ZSH_THEME_SQUANCHY_ICON_PYTHON}
typeset -g _SQUANCHY_RUBY=${(g::)ZSH_THEME_SQUANCHY_ICON_RUBY}

typeset -g _SQUANCHY_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/squanchy
typeset -gi _SQUANCHY_LTS_TTL=86400

typeset -g _SQUANCHY_RPROMPT=""
typeset -gA _SQUANCHY_LOCAL
typeset -g _SQUANCHY_LOCAL_PWD=""

_squanchy_lts() {
  emulate -L zsh
  local lang=$1
  local file=$_SQUANCHY_CACHE_DIR/lts-$lang
  local cached=""
  local -a st
  local now=$EPOCHSECONDS

  if [[ -r $file ]]; then
    cached=$(<$file)
    zstat -A st +mtime -- $file 2>/dev/null
    if (( ${st[1]:-0} + _SQUANCHY_LTS_TTL > now )); then
      print -r -- "$cached"
      return 0
    fi
  fi

  if (( $+functions[lts] )); then
    [[ -d $_SQUANCHY_CACHE_DIR ]] || command mkdir -p $_SQUANCHY_CACHE_DIR
    ( lts $lang > $file ) &>/dev/null </dev/null &!
  fi

  print -r -- "$cached"
}

_squanchy_has_update() {
  emulate -L zsh
  local -a l=(${(s/./)1}) c=(${(s/./)2})
  (( ${l[1]:-0} > ${c[1]:-0} \
    || (${l[1]:-0} == ${c[1]:-0} && ${l[2]:-0} > ${c[2]:-0}) \
    || (${l[1]:-0} == ${c[1]:-0} && ${l[2]:-0} == ${c[2]:-0} && ${l[3]:-0} > ${c[3]:-0}) ))
}

_squanchy_resolve_local() {
  emulate -L zsh
  [[ $_SQUANCHY_LOCAL_PWD == $PWD ]] && return 0
  _SQUANCHY_LOCAL_PWD=$PWD
  _SQUANCHY_LOCAL=()

  _git_in_repo || return 0
  local toplevel=$_GIT_TOPLEVEL
  [[ $toplevel == $HOME ]] && return 0

  local lang file
  for lang in node ruby python; do
    file=$toplevel/.$lang-version
    [[ -r $file ]] && _SQUANCHY_LOCAL[$lang]=$(<$file)
  done
}

_squanchy_version() {
  emulate -L zsh
  local lang=$1
  local local_version=${_SQUANCHY_LOCAL[$lang]}
  local global_version=""
  [[ -r $HOME/.$lang-version ]] && global_version=$(<$HOME/.$lang-version)
  local lts_version=$(_squanchy_lts $lang)

  if [[ -n $local_version ]]; then
    if _squanchy_version_installed $lang $local_version; then
      if _squanchy_has_update "$lts_version" "$local_version"; then
        print -r -- "${local_version}${ZSH_THEME_SQUANCHY_ICON_PIN}${ZSH_THEME_SQUANCHY_ICON_UP}"
      else
        print -r -- "${local_version}${ZSH_THEME_SQUANCHY_ICON_PIN}"
      fi
    else
      print -r -- "${local_version}${ZSH_THEME_SQUANCHY_ICON_PIN_ALT}"
    fi
    return 0
  fi

  if [[ -z $global_version ]]; then
    print -r -- "$ZSH_THEME_SQUANCHY_RPROMPT_EMPTY"
    return 0
  fi

  if [[ -z $lts_version ]]; then
    print -r -- "$global_version"
    return 0
  fi

  if _squanchy_has_update "$lts_version" "$global_version"; then
    print -r -- "${global_version}${ZSH_THEME_SQUANCHY_ICON_UP}"
    return 0
  fi

  print -r -- "$global_version"
}

_squanchy_version_installed() {
  emulate -L zsh
  local lang=$1 version=$2 root
  case $lang in
    node) root=${NODENV_ROOT:-$HOME/.nodenv} ;;
    ruby) root=${RBENV_ROOT:-$HOME/.rbenv} ;;
    python) root=${PYENV_ROOT:-$HOME/.pyenv} ;;
    *) return 1 ;;
  esac
  [[ -d $root/versions/$version ]]
}

_squanchy_php() {
  emulate -L zsh
  (( $+commands[php] )) || { print -r -- ""; return 0 }
  local first=${${(f)"$(php -v 2>/dev/null)"}[1]}
  local -a parts=(${(s/ /)first})
  print -r -- "${parts[2][1,3]}"
}

_squanchy_rprompt() {
  emulate -L zsh
  local -a seen segments
  local r
  [[ -z "$ZSH_THEME_RPROMPTS" ]] && ZSH_THEME_RPROMPTS=(node ruby python php)
  for r in $ZSH_THEME_RPROMPTS; do
    (( ${seen[(I)$r]} )) && continue
    seen+=$r
    case $r in
      node) segments+="%{$fg[green]%}${_SQUANCHY_NODE} $(_squanchy_version node)%{$reset_color%}" ;;
      ruby) segments+="%{$fg[red]%}${_SQUANCHY_RUBY} $(_squanchy_version ruby)%{$reset_color%}" ;;
      python) segments+="%{$fg[yellow]%}${_SQUANCHY_PYTHON} $(_squanchy_version python)%{$reset_color%}" ;;
      php) segments+="%{$fg[blue]%}${_SQUANCHY_PHP} $(_squanchy_php)%{$reset_color%}" ;;
    esac
  done
  _SQUANCHY_RPROMPT="${(j:  :)segments}"
}

_squanchy_chpwd() {
  _SQUANCHY_LOCAL_PWD=""
  _squanchy_resolve_local
}

_squanchy_precmd() {
  _squanchy_resolve_local
  _git_segment
  _squanchy_rprompt
}

add-zsh-hook chpwd _squanchy_chpwd
add-zsh-hook precmd _squanchy_precmd

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} '
PROMPT+='%1~ '
PROMPT+='${_GIT_SEGMENT}'
RPROMPT='${_SQUANCHY_RPROMPT}'
