autoload -U colors && colors
zmodload zsh/datetime
zmodload -F zsh/stat b:zstat
source ${0:A:h}/lib/hooks.zsh
source ${0:A:h}/lib/git.zsh
source ${0:A:h}/lib/title.zsh

ZSH_THEME_RUNTIMES_RPROMPT_EMPTY="n/a"
ZSH_THEME_RUNTIMES_ICON_NODE="\\ue718"
ZSH_THEME_RUNTIMES_ICON_PHP="\\ue608"
ZSH_THEME_RUNTIMES_ICON_PYTHON="\\ue606"
ZSH_THEME_RUNTIMES_ICON_RUBY="\\ueb48"
ZSH_THEME_RUNTIMES_ICON_UP="↑"
ZSH_THEME_RUNTIMES_ICON_PIN="⚑"
ZSH_THEME_RUNTIMES_ICON_PIN_ALT="⚐"

[[ -z "$ZSH_THEME_RUNTIMES_RPROMPTS" ]] && ZSH_THEME_RUNTIMES_RPROMPTS=(node python ruby php)

typeset -g _RUNTIMES_NODE=${(g::)ZSH_THEME_RUNTIMES_ICON_NODE}
typeset -g _RUNTIMES_PHP=${(g::)ZSH_THEME_RUNTIMES_ICON_PHP}
typeset -g _RUNTIMES_PYTHON=${(g::)ZSH_THEME_RUNTIMES_ICON_PYTHON}
typeset -g _RUNTIMES_RUBY=${(g::)ZSH_THEME_RUNTIMES_ICON_RUBY}

typeset -g _RUNTIMES_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/runtimes
typeset -gi _RUNTIMES_CACHE_TTL=86400

typeset -g _RUNTIMES_RPROMPT=""
typeset -gA _RUNTIMES_LOCAL
typeset -g _RUNTIMES_LOCAL_PWD=""

_runtimes_first_line() {
  emulate -L zsh
  local _v
  read -r _v < $2 2>/dev/null
  : ${(P)1::=${_v//$'\r'/}}
}

_runtimes_lts() {
  emulate -L zsh
  local lang=$2
  local file=$_RUNTIMES_CACHE_DIR/lts-$lang
  local cached="" now=$EPOCHSECONDS
  local -a st

  if [[ -r $file ]]; then
    read -r cached < $file
    cached=${cached//$'\r'/}
    zstat -A st +mtime -- $file 2>/dev/null
    if (( ${st[1]:-0} + _RUNTIMES_CACHE_TTL > now )); then
      : ${(P)1::=$cached}
      return 0
    fi
  fi

  if (( $+functions[lts] )); then
    [[ -d $_RUNTIMES_CACHE_DIR ]] || command mkdir -p $_RUNTIMES_CACHE_DIR
    local lock=$file.lock
    if [[ -d $lock ]]; then
      zstat -A st +mtime -- $lock 2>/dev/null
      (( ${st[1]:-0} + 60 < now )) && command rmdir $lock 2>/dev/null
    fi
    if command mkdir $lock 2>/dev/null; then
      (
        trap 'command rmdir $lock 2>/dev/null' EXIT
        local tmp=$file.$sysparams[pid]
        if lts $lang > $tmp 2>/dev/null && [[ -s $tmp ]]; then
          command mv -f $tmp $file
        else
          command rm -f $tmp
        fi
      ) &>/dev/null </dev/null &!
    fi
  fi

  : ${(P)1::=$cached}
}

_runtimes_has_update() {
  emulate -L zsh
  local -a l=(${(s/./)${${1#v}%%[-+]*}}) c=(${(s/./)${${2#v}%%[-+]*}})
  local -i l1=10#${l[1]:-0} l2=10#${l[2]:-0} l3=10#${l[3]:-0}
  local -i c1=10#${c[1]:-0} c2=10#${c[2]:-0} c3=10#${c[3]:-0}
  (( l1 > c1 || (l1 == c1 && l2 > c2) || (l1 == c1 && l2 == c2 && l3 > c3) ))
}

_runtimes_resolve_local() {
  emulate -L zsh
  [[ $_RUNTIMES_LOCAL_PWD == $PWD ]] && return 0
  _RUNTIMES_LOCAL_PWD=$PWD
  _RUNTIMES_LOCAL=()

  _git_in_repo || return 0
  local toplevel=$_GIT_TOPLEVEL
  [[ $toplevel == $HOME ]] && return 0

  local lang file version
  for lang in node ruby python; do
    file=$toplevel/.$lang-version
    if [[ -r $file ]]; then
      _runtimes_first_line version $file
      [[ -n $version ]] && _RUNTIMES_LOCAL[$lang]=$version
    fi
  done
}

_runtimes_version() {
  emulate -L zsh
  local lang=$2
  local local_version=${_RUNTIMES_LOCAL[$lang]}
  local global_version="" lts_version="" out=""
  [[ -r $HOME/.$lang-version ]] && _runtimes_first_line global_version $HOME/.$lang-version
  _runtimes_lts lts_version $lang

  if [[ -n $local_version ]]; then
    if _runtimes_version_installed $lang $local_version; then
      out=${local_version}${ZSH_THEME_RUNTIMES_ICON_PIN}
      _runtimes_has_update "$lts_version" "$local_version" && out+=$ZSH_THEME_RUNTIMES_ICON_UP
    else
      out=${local_version}${ZSH_THEME_RUNTIMES_ICON_PIN_ALT}
    fi
  elif [[ -z $global_version ]]; then
    out=$ZSH_THEME_RUNTIMES_RPROMPT_EMPTY
  else
    out=$global_version
    _runtimes_has_update "$lts_version" "$global_version" && out+=$ZSH_THEME_RUNTIMES_ICON_UP
  fi

  out=${out//\%/%%}
  : ${(P)1::=$out}
}

_runtimes_version_installed() {
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

_runtimes_php() {
  emulate -L zsh
  local bin=$commands[php]
  [[ -n $bin ]] || { : ${(P)1::=""}; return 0 }

  local file=$_RUNTIMES_CACHE_DIR/php-version
  local now=$EPOCHSECONDS ver=""
  local -a sb sf sl
  zstat -A sb +mtime -- $bin 2>/dev/null
  if [[ -r $file ]]; then
    zstat -A sf +mtime -- $file 2>/dev/null
    read -r ver < $file
    ver=${ver//$'\r'/}
    if (( ${sf[1]:-0} >= ${sb[1]:-1} )); then
      : ${(P)1::=${ver:+${(j:.:)${(@s:.:)ver}[1,2]}}}
      return 0
    fi
  fi

  local lock=$file.lock
  [[ -d $_RUNTIMES_CACHE_DIR ]] || command mkdir -p $_RUNTIMES_CACHE_DIR
  if [[ -d $lock ]]; then
    zstat -A sl +mtime -- $lock 2>/dev/null
    (( ${sl[1]:-0} + 60 < now )) && command rmdir $lock 2>/dev/null
  fi
  if command mkdir $lock 2>/dev/null; then
    (
      trap 'command rmdir $lock 2>/dev/null' EXIT
      local first=${${(f)"$(command $bin -v 2>/dev/null)"}[1]}
      local -a parts=(${(s/ /)first})
      local tmp=$file.$sysparams[pid]
      if [[ -n ${parts[2]} ]] && print -r -- ${parts[2]} > $tmp 2>/dev/null; then
        command mv -f $tmp $file
      else
        command rm -f $tmp
      fi
    ) &>/dev/null </dev/null &!
  fi

  : ${(P)1::=${ver:+${(j:.:)${(@s:.:)ver}[1,2]}}}
}

_runtimes_rprompt() {
  emulate -L zsh
  local -a seen segments
  local r color icon version
  [[ -z "$ZSH_THEME_RUNTIMES_RPROMPTS" ]] && ZSH_THEME_RUNTIMES_RPROMPTS=(node python ruby php)
  for r in $ZSH_THEME_RUNTIMES_RPROMPTS; do
    (( ${seen[(I)$r]} )) && continue
    seen+=$r
    case $r in
      node) color=$fg[green]; icon=$_RUNTIMES_NODE; _runtimes_version version node ;;
      ruby) color=$fg[red]; icon=$_RUNTIMES_RUBY; _runtimes_version version ruby ;;
      python) color=$fg[yellow]; icon=$_RUNTIMES_PYTHON; _runtimes_version version python ;;
      php) color=$fg[blue]; icon=$_RUNTIMES_PHP; _runtimes_php version ;;
      *) continue ;;
    esac
    [[ -z $version || $version == $ZSH_THEME_RUNTIMES_RPROMPT_EMPTY ]] && continue
    segments+="%{$color%}${icon} ${version}%{$reset_color%}"
  done
  _RUNTIMES_RPROMPT="${(j:  :)segments}"
}

_runtimes_chpwd() {
  _RUNTIMES_LOCAL_PWD=""
}

_runtimes_precmd() {
  _runtimes_resolve_local
  _git_segment
  _runtimes_rprompt
}

_theme_hook chpwd _runtimes_chpwd
_theme_hook precmd _runtimes_precmd

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} '
PROMPT+='%1~ '
PROMPT+='${_GIT_SEGMENT}'
RPROMPT='${_RUNTIMES_RPROMPT}'
