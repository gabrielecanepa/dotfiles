autoload -U colors && colors
zmodload zsh/datetime
zmodload -F zsh/stat b:zstat
source ${0:A:h}/lib/hooks.zsh
source ${0:A:h}/lib/git.zsh
source ${0:A:h}/lib/title.zsh

ZSH_THEME_SQUANCHY_RPROMPT_EMPTY="n/a"
ZSH_THEME_SQUANCHY_ICON_NODE="\\ue718"
ZSH_THEME_SQUANCHY_ICON_NPM="\\ue71e"
ZSH_THEME_SQUANCHY_ICON_PNPM="\\ue865"
ZSH_THEME_SQUANCHY_ICON_BUN="\\ue76f"
ZSH_THEME_SQUANCHY_ICON_YARN="\\ue8ec"
ZSH_THEME_SQUANCHY_ICON_PHP="\\ue608"
ZSH_THEME_SQUANCHY_ICON_PYTHON="\\ue606"
ZSH_THEME_SQUANCHY_ICON_RUBY="\\ueb48"
ZSH_THEME_SQUANCHY_ICON_UP="↑"
ZSH_THEME_SQUANCHY_ICON_PIN="⚑"
ZSH_THEME_SQUANCHY_ICON_PIN_ALT="⚐"

[[ -z "$ZSH_THEME_SQUANCHY_RPROMPTS" ]] && ZSH_THEME_SQUANCHY_RPROMPTS=(node python ruby php)

typeset -g _SQUANCHY_NODE=${(g::)ZSH_THEME_SQUANCHY_ICON_NODE}
typeset -g _SQUANCHY_PHP=${(g::)ZSH_THEME_SQUANCHY_ICON_PHP}
typeset -g _SQUANCHY_PYTHON=${(g::)ZSH_THEME_SQUANCHY_ICON_PYTHON}
typeset -g _SQUANCHY_RUBY=${(g::)ZSH_THEME_SQUANCHY_ICON_RUBY}

typeset -gA _SQUANCHY_PM_ICONS=(
  npm "${(g::)ZSH_THEME_SQUANCHY_ICON_NPM}"
  pnpm "${(g::)ZSH_THEME_SQUANCHY_ICON_PNPM}"
  bun "${(g::)ZSH_THEME_SQUANCHY_ICON_BUN}"
  yarn "${(g::)ZSH_THEME_SQUANCHY_ICON_YARN}"
)
typeset -gA _SQUANCHY_PM_COLORS=(npm red pnpm yellow bun white yarn cyan)

typeset -g _SQUANCHY_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/squanchy
typeset -gi _SQUANCHY_CACHE_TTL=86400

typeset -g _SQUANCHY_RPROMPT=""
typeset -gA _SQUANCHY_LOCAL
typeset -ga _SQUANCHY_PROJECT
typeset -g _SQUANCHY_LOCAL_PWD=""

_squanchy_first_line() {
  emulate -L zsh
  local _v
  read -r _v < $2 2>/dev/null
  : ${(P)1::=${_v//$'\r'/}}
}

_squanchy_json_value() {
  emulate -L zsh -o extended_glob
  local file=$3 key=$2 line
  while IFS= read -r line; do
    if [[ $line == *\"$key\":* ]]; then
      line=${line#*\"$key\":[[:space:]]#\"}
      : ${(P)1::=${line%%\"*}}
      return 0
    fi
  done < $file
  : ${(P)1::=""}
  return 1
}

_squanchy_lts() {
  emulate -L zsh
  local lang=$2
  local file=$_SQUANCHY_CACHE_DIR/lts-$lang
  local cached="" now=$EPOCHSECONDS
  local -a st

  if [[ -r $file ]]; then
    read -r cached < $file
    cached=${cached//$'\r'/}
    zstat -A st +mtime -- $file 2>/dev/null
    if (( ${st[1]:-0} + _SQUANCHY_CACHE_TTL > now )); then
      : ${(P)1::=$cached}
      return 0
    fi
  fi

  if (( $+functions[lts] )); then
    [[ -d $_SQUANCHY_CACHE_DIR ]] || command mkdir -p $_SQUANCHY_CACHE_DIR
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

_squanchy_latest() {
  emulate -L zsh
  local pkg=$2
  local file=$_SQUANCHY_CACHE_DIR/latest-$pkg
  local cached="" now=$EPOCHSECONDS
  local -a st

  if [[ -r $file ]]; then
    read -r cached < $file
    zstat -A st +mtime -- $file 2>/dev/null
    if (( ${st[1]:-0} + _SQUANCHY_CACHE_TTL > now )); then
      : ${(P)1::=${cached//$'\r'/}}
      return 0
    fi
  fi

  if (( $+commands[curl] && $+commands[jq] )); then
    [[ -d $_SQUANCHY_CACHE_DIR ]] || command mkdir -p $_SQUANCHY_CACHE_DIR
    local lock=$file.lock
    if [[ -d $lock ]]; then
      zstat -A st +mtime -- $lock 2>/dev/null
      (( ${st[1]:-0} + 60 < now )) && command rmdir $lock 2>/dev/null
    fi
    if command mkdir $lock 2>/dev/null; then
      (
        trap 'command rmdir $lock 2>/dev/null' EXIT
        local tmp=$file.$sysparams[pid]
        if command curl -fsSL --max-time 2 "https://registry.npmjs.org/$pkg/latest" \
          | command jq -re .version > $tmp 2>/dev/null; then
          command mv -f $tmp $file
        else
          command rm -f $tmp
        fi
      ) &>/dev/null </dev/null &!
    fi
  fi

  : ${(P)1::=${cached//$'\r'/}}
}

_squanchy_has_update() {
  emulate -L zsh
  local -a l=(${(s/./)${${1#v}%%[-+]*}}) c=(${(s/./)${${2#v}%%[-+]*}})
  local -i l1=10#${l[1]:-0} l2=10#${l[2]:-0} l3=10#${l[3]:-0}
  local -i c1=10#${c[1]:-0} c2=10#${c[2]:-0} c3=10#${c[3]:-0}
  (( l1 > c1 || (l1 == c1 && l2 > c2) || (l1 == c1 && l2 == c2 && l3 > c3) ))
}

_squanchy_detect_manager() {
  emulate -L zsh
  local toplevel=$1
  local pkg=$toplevel/package.json
  _SQUANCHY_LOCAL[manager]=""
  _SQUANCHY_LOCAL[manager_pinned]=""
  [[ -r $pkg ]] || return 1

  local field
  if _squanchy_json_value field packageManager $pkg && [[ -n $field ]]; then
    local name=${field%%@*}
    if [[ -n $name ]]; then
      _SQUANCHY_LOCAL[manager]=$name
      [[ $field == *@* ]] && _SQUANCHY_LOCAL[manager_pinned]=${${field#*@}%%+*}
      return 0
    fi
  fi

  local lock
  for lock in pnpm-lock.yaml:pnpm bun.lock:bun bun.lockb:bun yarn.lock:yarn package-lock.json:npm npm-shrinkwrap.json:npm; do
    [[ -e $toplevel/${lock%%:*} ]] && { _SQUANCHY_LOCAL[manager]=${lock##*:}; return 0 }
  done

  _SQUANCHY_LOCAL[manager]=npm
}

_squanchy_detect_project() {
  emulate -L zsh
  local toplevel=$1

  if [[ -e $toplevel/package.json || -n ${_SQUANCHY_LOCAL[node]} ]]; then
    _SQUANCHY_PROJECT+=node
    _squanchy_detect_manager $toplevel
  fi

  if [[ -e $toplevel/pyproject.toml || -e $toplevel/requirements.txt \
    || -e $toplevel/setup.py || -e $toplevel/Pipfile || -n ${_SQUANCHY_LOCAL[python]} ]]; then
    _SQUANCHY_PROJECT+=python
  fi

  local -a gemspecs=($toplevel/*.gemspec(N[1]))
  if [[ -e $toplevel/Gemfile || -n ${_SQUANCHY_LOCAL[ruby]} ]] || (( ${#gemspecs} )); then
    _SQUANCHY_PROJECT+=ruby
  fi

  [[ -e $toplevel/composer.json ]] && _SQUANCHY_PROJECT+=php
}

_squanchy_resolve_local() {
  emulate -L zsh
  [[ $_SQUANCHY_LOCAL_PWD == $PWD ]] && return 0
  _SQUANCHY_LOCAL_PWD=$PWD
  _SQUANCHY_LOCAL=()
  _SQUANCHY_PROJECT=()

  _git_in_repo || return 0
  local toplevel=$_GIT_TOPLEVEL
  [[ $toplevel == $HOME ]] && return 0

  local lang file version
  for lang in node ruby python; do
    file=$toplevel/.$lang-version
    if [[ -r $file ]]; then
      _squanchy_first_line version $file
      [[ -n $version ]] && _SQUANCHY_LOCAL[$lang]=$version
    fi
  done

  _squanchy_detect_project $toplevel
}

_squanchy_version() {
  emulate -L zsh
  local lang=$2
  local local_version=${_SQUANCHY_LOCAL[$lang]}
  local global_version="" lts_version="" out=""
  [[ -r $HOME/.$lang-version ]] && _squanchy_first_line global_version $HOME/.$lang-version
  _squanchy_lts lts_version $lang

  if [[ -n $local_version ]]; then
    if _squanchy_version_installed $lang $local_version; then
      out=${local_version}${ZSH_THEME_SQUANCHY_ICON_PIN}
      _squanchy_has_update "$lts_version" "$local_version" && out+=$ZSH_THEME_SQUANCHY_ICON_UP
    else
      out=${local_version}${ZSH_THEME_SQUANCHY_ICON_PIN_ALT}
    fi
  elif [[ -z $global_version ]]; then
    out=$ZSH_THEME_SQUANCHY_RPROMPT_EMPTY
  else
    out=$global_version
    _squanchy_has_update "$lts_version" "$global_version" && out+=$ZSH_THEME_SQUANCHY_ICON_UP
  fi

  out=${out//\%/%%}
  : ${(P)1::=$out}
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
  local bin=$commands[php]
  [[ -n $bin ]] || { : ${(P)1::=""}; return 0 }

  local file=$_SQUANCHY_CACHE_DIR/php-version
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
  [[ -d $_SQUANCHY_CACHE_DIR ]] || command mkdir -p $_SQUANCHY_CACHE_DIR
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

_squanchy_corepack() {
  emulate -L zsh
  local pm=$2
  local file=${COREPACK_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/node/corepack}/lastKnownGood.json
  [[ -r $file ]] || { : ${(P)1::=""}; return 0 }
  _squanchy_json_value $1 $pm $file
}

_squanchy_pm_version() {
  emulate -L zsh
  local pm=$2 corepack=$3

  case $pm in
    pnpm|yarn)
      if [[ -n $corepack ]]; then
        local ref=${corepack%%+*}
        [[ -n $ref ]] && { : ${(P)1::=$ref}; return 0 }
      fi
      ;;
  esac

  local nv=${_SQUANCHY_LOCAL[node]}
  [[ -z $nv && -r $HOME/.node-version ]] && _squanchy_first_line nv $HOME/.node-version
  local root=${NODENV_ROOT:-$HOME/.nodenv}

  case $pm in
    npm|pnpm|yarn)
      local pkg=$root/versions/$nv/lib/node_modules/$pm/package.json
      if [[ -r $pkg ]]; then
        local ver
        _squanchy_json_value ver version $pkg
        [[ -n $ver ]] && { : ${(P)1::=$ver}; return 0 }
      fi
      ;;
    bun)
      local bin=${commands[bun]:-${BUN_INSTALL:-$HOME/.bun}/bin/bun}
      if [[ -x $bin ]]; then
        local file=$_SQUANCHY_CACHE_DIR/bun-version
        local now=$EPOCHSECONDS ver=""
        local -a sb sf sl
        zstat -A sb +mtime -- $bin 2>/dev/null
        if [[ -r $file ]]; then
          zstat -A sf +mtime -- $file 2>/dev/null
          read -r ver < $file
          if (( ${sf[1]:-0} >= ${sb[1]:-1} )); then
            : ${(P)1::=${ver//$'\r'/}}
            return 0
          fi
        fi
        local lock=$file.lock
        [[ -d $_SQUANCHY_CACHE_DIR ]] || command mkdir -p $_SQUANCHY_CACHE_DIR
        if [[ -d $lock ]]; then
          zstat -A sl +mtime -- $lock 2>/dev/null
          (( ${sl[1]:-0} + 60 < now )) && command rmdir $lock 2>/dev/null
        fi
        if command mkdir $lock 2>/dev/null; then
          (
            trap 'command rmdir $lock 2>/dev/null' EXIT
            local tmp=$file.$sysparams[pid]
            if command $bin --version > $tmp 2>/dev/null && [[ -s $tmp ]]; then
              command mv -f $tmp $file
            else
              command rm -f $tmp
            fi
          ) &>/dev/null </dev/null &!
        fi
        [[ -n $ver ]] && { : ${(P)1::=${ver//$'\r'/}}; return 0 }
      fi
      ;;
  esac

  : ${(P)1::=""}
}

_squanchy_pm_segment() {
  emulate -L zsh
  local pm=$2 corepack=$3 pinned=$4
  local version="" latest=""

  if [[ -n $pinned ]]; then
    version=$pinned
  else
    _squanchy_pm_version version $pm "$corepack"
  fi
  [[ -z $version ]] && { : ${(P)1::=""}; return 1 }

  _squanchy_latest latest $pm
  local out=$version
  [[ -n $pinned ]] && out+=$ZSH_THEME_SQUANCHY_ICON_PIN
  [[ -n $latest ]] && _squanchy_has_update $latest $version && out+=$ZSH_THEME_SQUANCHY_ICON_UP

  out=${out//\%/%%}
  : ${(P)1::="%F{${_SQUANCHY_PM_COLORS[$pm]}}${_SQUANCHY_PM_ICONS[$pm]} ${out}%f"}
}

_squanchy_rprompt() {
  emulate -L zsh
  local -a langs seen segments
  local r color icon version manager pm_seg corepack

  if (( ${#_SQUANCHY_PROJECT} )); then
    langs=($_SQUANCHY_PROJECT)
  else
    [[ -z "$ZSH_THEME_SQUANCHY_RPROMPTS" ]] && ZSH_THEME_SQUANCHY_RPROMPTS=(node python ruby php)
    langs=($ZSH_THEME_SQUANCHY_RPROMPTS)
  fi

  for r in $langs; do
    (( ${seen[(I)$r]} )) && continue
    seen+=$r
    case $r in
      node) color=$fg[green]; icon=$_SQUANCHY_NODE; _squanchy_version version node ;;
      ruby) color=$fg[red]; icon=$_SQUANCHY_RUBY; _squanchy_version version ruby ;;
      python) color=$fg[yellow]; icon=$_SQUANCHY_PYTHON; _squanchy_version version python ;;
      php) color=$fg[blue]; icon=$_SQUANCHY_PHP; _squanchy_php version ;;
      *) continue ;;
    esac
    [[ -z $version || $version == $ZSH_THEME_SQUANCHY_RPROMPT_EMPTY ]] && continue
    segments+="%{$color%}${icon} ${version}%{$reset_color%}"

    manager=${_SQUANCHY_LOCAL[manager]}
    if [[ $r == node && -n $manager && -n ${_SQUANCHY_PM_ICONS[$manager]} ]]; then
      _squanchy_corepack corepack $manager
      _squanchy_pm_segment pm_seg $manager "$corepack" "${_SQUANCHY_LOCAL[manager_pinned]}" \
        && segments+=$pm_seg
    fi
  done
  _SQUANCHY_RPROMPT="${(j:  :)segments}"
}

_squanchy_chpwd() {
  _SQUANCHY_LOCAL_PWD=""
}

_squanchy_precmd() {
  _squanchy_resolve_local
  _git_segment
  _squanchy_rprompt
}

_theme_hook chpwd _squanchy_chpwd
_theme_hook precmd _squanchy_precmd

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} '
PROMPT+='%1~ '
PROMPT+='${_GIT_SEGMENT}'
RPROMPT='${_SQUANCHY_RPROMPT}'
