autoload -U colors && colors
autoload -U add-zsh-hook
zmodload zsh/datetime
zmodload -F zsh/stat b:zstat
source ${0:A:h}/lib/git.zsh
source ${0:A:h}/lib/title.zsh

ZSH_THEME_NODE_RPROMPT_EMPTY="n/a"
ZSH_THEME_NODE_ICON_NODE="\\ue718"
ZSH_THEME_NODE_ICON_NPM="\\ue71e"
ZSH_THEME_NODE_ICON_PNPM="\\ue865"
ZSH_THEME_NODE_ICON_BUN="\\ue76f"
ZSH_THEME_NODE_ICON_YARN="\\ue8ec"
ZSH_THEME_NODE_ICON_UP="↑"
ZSH_THEME_NODE_ICON_PIN="⚑"
ZSH_THEME_NODE_ICON_PIN_ALT="⚐"

typeset -g _NODE_NODE=${(g::)ZSH_THEME_NODE_ICON_NODE}
typeset -g _NODE_NPM=${(g::)ZSH_THEME_NODE_ICON_NPM}
typeset -g _NODE_PNPM=${(g::)ZSH_THEME_NODE_ICON_PNPM}
typeset -g _NODE_BUN=${(g::)ZSH_THEME_NODE_ICON_BUN}
typeset -g _NODE_YARN=${(g::)ZSH_THEME_NODE_ICON_YARN}

typeset -gA _NODE_ICONS=(node "$_NODE_NODE" npm "$_NODE_NPM" pnpm "$_NODE_PNPM" bun "$_NODE_BUN" yarn "$_NODE_YARN")
typeset -gA _NODE_COLORS=(node 035 npm 196 pnpm 214 bun 230 yarn 039)

typeset -g _NODE_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/node-theme
typeset -gi _NODE_LATEST_TTL=86400

typeset -g _NODE_RPROMPT=""
typeset -gA _NODE_LOCAL
typeset -g _NODE_LOCAL_PWD=""

_node_first_line() {
  emulate -L zsh
  local _v
  read -r _v < $2 2>/dev/null
  : ${(P)1::=${_v//$'\r'/}}
}

_node_json_value() {
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

_node_escape() {
  emulate -L zsh
  : ${(P)1::=${${(P)1}//\%/%%}}
}

_node_semver_gt() {
  emulate -L zsh
  local -a l=(${(s/./)${${1#v}%%[-+]*}}) c=(${(s/./)${${2#v}%%[-+]*}})
  local -i l1=10#${l[1]:-0} l2=10#${l[2]:-0} l3=10#${l[3]:-0}
  local -i c1=10#${c[1]:-0} c2=10#${c[2]:-0} c3=10#${c[3]:-0}
  (( l1 > c1 || (l1 == c1 && l2 > c2) || (l1 == c1 && l2 == c2 && l3 > c3) ))
}

_node_latest() {
  emulate -L zsh
  local pkg=$2
  local file=$_NODE_CACHE_DIR/latest-$pkg
  local cached="" now=$EPOCHSECONDS
  local -a st

  if [[ -r $file ]]; then
    read -r cached < $file
    zstat -A st +mtime -- $file 2>/dev/null
    if (( ${st[1]:-0} + _NODE_LATEST_TTL > now )); then
      : ${(P)1::=${cached//$'\r'/}}
      return 0
    fi
  fi

  if (( $+commands[curl] && $+commands[jq] )); then
    [[ -d $_NODE_CACHE_DIR ]] || command mkdir -p $_NODE_CACHE_DIR
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

_node_pm_version() {
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

  local nv=${_NODE_LOCAL[node]}
  [[ -z $nv && -r $HOME/.node-version ]] && { read -r nv < $HOME/.node-version; nv=${nv//$'\r'/} }
  local root=${NODENV_ROOT:-$HOME/.nodenv}

  case $pm in
    npm|pnpm|yarn)
      local pkg=$root/versions/$nv/lib/node_modules/$pm/package.json
      if [[ -r $pkg ]]; then
        local ver
        _node_json_value ver version $pkg
        [[ -n $ver ]] && { : ${(P)1::=$ver}; return 0 }
      fi
      ;;
    bun)
      local bin=${commands[bun]:-${BUN_INSTALL:-$HOME/.bun}/bin/bun}
      if [[ -x $bin ]]; then
        local file=$_NODE_CACHE_DIR/bun-version
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
        [[ -d $_NODE_CACHE_DIR ]] || command mkdir -p $_NODE_CACHE_DIR
        if [[ -d $lock ]]; then
          zstat -A sl +mtime -- $lock 2>/dev/null
          (( ${sl[1]:-0} + _NODE_LATEST_TTL < now )) && command rmdir $lock 2>/dev/null
        fi
        if command mkdir $lock 2>/dev/null; then
          (
            local tmp=$file.$sysparams[pid]
            if command $bin --version > $tmp 2>/dev/null && [[ -s $tmp ]]; then
              command mv -f $tmp $file
              command rmdir $lock 2>/dev/null
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

_node_detect_manager() {
  emulate -L zsh
  local toplevel=$1
  local pkg=$toplevel/package.json
  _NODE_LOCAL[manager]=""
  _NODE_LOCAL[manager_pinned]=""
  [[ -r $pkg ]] || return 1

  local field
  if _node_json_value field packageManager $pkg && [[ -n $field ]]; then
    local name=${field%%@*}
    if [[ -n $name ]]; then
      _NODE_LOCAL[manager]=$name
      [[ $field == *@* ]] && _NODE_LOCAL[manager_pinned]=${${field#*@}%%+*}
      return 0
    fi
  fi

  local lock
  for lock in pnpm-lock.yaml:pnpm bun.lock:bun bun.lockb:bun yarn.lock:yarn package-lock.json:npm npm-shrinkwrap.json:npm; do
    [[ -e $toplevel/${lock%%:*} ]] && { _NODE_LOCAL[manager]=${lock##*:}; return 0 }
  done

  return 1
}

_node_resolve_local() {
  emulate -L zsh
  [[ $_NODE_LOCAL_PWD == $PWD ]] && return 0
  _NODE_LOCAL_PWD=$PWD
  _NODE_LOCAL=()

  _git_in_repo || return 0
  local toplevel=$_GIT_TOPLEVEL
  [[ $toplevel == $HOME ]] && return 0

  [[ -r $toplevel/.node-version ]] && _node_first_line '_NODE_LOCAL[node]' $toplevel/.node-version
  _node_detect_manager $toplevel
}

_node_version_installed() {
  emulate -L zsh
  local version=$1 root=${NODENV_ROOT:-$HOME/.nodenv}
  [[ -d $root/versions/$version ]]
}

_node_node_segment() {
  emulate -L zsh
  local local_version=${_NODE_LOCAL[node]}
  local global_version=""
  [[ -r $HOME/.node-version ]] && { read -r global_version < $HOME/.node-version; global_version=${global_version//$'\r'/} }
  local lts_version=""
  _node_lts lts_version

  local out
  if [[ -n $local_version ]]; then
    if _node_version_installed $local_version; then
      if [[ -n $lts_version ]] && _node_semver_gt $lts_version $local_version; then
        out="${local_version}${ZSH_THEME_NODE_ICON_PIN}${ZSH_THEME_NODE_ICON_UP}"
      else
        out="${local_version}${ZSH_THEME_NODE_ICON_PIN}"
      fi
    else
      out="${local_version}${ZSH_THEME_NODE_ICON_PIN_ALT}"
    fi
  elif [[ -z $global_version ]]; then
    out=$ZSH_THEME_NODE_RPROMPT_EMPTY
  elif [[ -n $lts_version ]] && _node_semver_gt $lts_version $global_version; then
    out="${global_version}${ZSH_THEME_NODE_ICON_UP}"
  else
    out=$global_version
  fi

  _node_escape out
  : ${(P)1::=$out}
}

_node_lts() {
  emulate -L zsh
  local file=$_NODE_CACHE_DIR/lts-node
  local cached="" now=$EPOCHSECONDS
  local -a st

  if [[ -r $file ]]; then
    read -r cached < $file
    zstat -A st +mtime -- $file 2>/dev/null
    if (( ${st[1]:-0} + _NODE_LATEST_TTL > now )); then
      : ${(P)1::=${cached//$'\r'/}}
      return 0
    fi
  fi

  if (( $+functions[lts] )); then
    [[ -d $_NODE_CACHE_DIR ]] || command mkdir -p $_NODE_CACHE_DIR
    local lock=$file.lock
    if [[ -d $lock ]]; then
      zstat -A st +mtime -- $lock 2>/dev/null
      (( ${st[1]:-0} + 60 < now )) && command rmdir $lock 2>/dev/null
    fi
    if command mkdir $lock 2>/dev/null; then
      (
        trap 'command rmdir $lock 2>/dev/null' EXIT
        local tmp=$file.$sysparams[pid]
        if lts node > $tmp 2>/dev/null && [[ -s $tmp ]]; then
          command mv -f $tmp $file
        else
          command rm -f $tmp
        fi
      ) &>/dev/null </dev/null &!
    fi
  fi

  : ${(P)1::=${cached//$'\r'/}}
}

_node_pm_segment() {
  emulate -L zsh
  local pm=$2 corepack=$3
  local pinned=$4 version="" latest=""

  if [[ -n $pinned ]]; then
    version=$pinned
  else
    _node_pm_version version $pm "$corepack"
  fi
  [[ -z $version ]] && { : ${(P)1::=""}; return 1 }

  _node_latest latest $pm
  local out=$version
  [[ -n $pinned ]] && out+=$ZSH_THEME_NODE_ICON_PIN
  [[ -n $latest ]] && _node_semver_gt $latest $version && out+=$ZSH_THEME_NODE_ICON_UP

  _node_escape out
  : ${(P)1::="%F{${_NODE_COLORS[$pm]}}${_NODE_ICONS[$pm]} ${out}%f"}
}

_node_corepack() {
  emulate -L zsh
  local pm=$2
  local file=${COREPACK_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/node/corepack}/lastKnownGood.json
  [[ -r $file ]] || { : ${(P)1::=""}; return 0 }
  _node_json_value $1 $pm $file
}

_node_rprompt() {
  emulate -L zsh
  local -a segments
  local node_seg pm_seg corepack
  local manager=${_NODE_LOCAL[manager]}

  _node_node_segment node_seg
  segments+="%F{${_NODE_COLORS[node]}}${_NODE_NODE} ${node_seg}%f"

  if [[ -n $manager && -n ${_NODE_ICONS[$manager]} ]]; then
    _node_corepack corepack $manager
    _node_pm_segment pm_seg $manager "$corepack" "${_NODE_LOCAL[manager_pinned]}" \
      && segments+=$pm_seg
  fi

  _NODE_RPROMPT="${(j:  :)segments}"
}

_node_chpwd() {
  _NODE_LOCAL_PWD=""
}

_node_precmd() {
  _node_resolve_local
  _git_segment
  _node_rprompt
}

add-zsh-hook chpwd _node_chpwd
add-zsh-hook precmd _node_precmd

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} '
PROMPT+='%1~ '
PROMPT+='${_GIT_SEGMENT}'
RPROMPT='${_NODE_RPROMPT}'
