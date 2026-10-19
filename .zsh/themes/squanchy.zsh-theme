autoload -U colors && colors
zmodload zsh/datetime
zmodload -F zsh/stat b:zstat
zmodload -F zsh/system p:sysparams
autoload -U add-zsh-hook

ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}*"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}*"

[[ -z $ZSH_THEME_SQUANCHY_RPROMPTS ]] && ZSH_THEME_SQUANCHY_RPROMPTS=(node python ruby php)
ZSH_THEME_SQUANCHY_GAP=4
ZSH_THEME_SQUANCHY_EMPTY=n/a
ZSH_THEME_SQUANCHY_ICON_NODE='\ue718'
ZSH_THEME_SQUANCHY_ICON_NPM='\ue71e'
ZSH_THEME_SQUANCHY_ICON_PNPM='\ue865'
ZSH_THEME_SQUANCHY_ICON_BUN='\ue76f'
ZSH_THEME_SQUANCHY_ICON_YARN='\ue8ec'
ZSH_THEME_SQUANCHY_ICON_PHP='\ue608'
ZSH_THEME_SQUANCHY_ICON_PYTHON='\ue606'
ZSH_THEME_SQUANCHY_ICON_RUBY='\ueb48'
ZSH_THEME_SQUANCHY_ICON_UP=↑
ZSH_THEME_SQUANCHY_ICON_PIN=⚑
ZSH_THEME_SQUANCHY_ICON_PIN_ALT=⚐
ZSH_THEME_GIT_ICON_BRANCH='\ue727'
ZSH_THEME_GIT_ICON_COMMIT='\ue729'
ZSH_THEME_GIT_ICON_GITHUB='\uf09b'
ZSH_THEME_GIT_ICON_GITLAB='\uf296'

typeset -ga _THEME_HOOKS

() {
  emulate -L zsh
  local spec
  for spec in $_THEME_HOOKS; do
    add-zsh-hook -d ${spec%%:*} ${spec#*:}
  done
  _THEME_HOOKS=()
}

_theme_hook() {
  emulate -L zsh
  add-zsh-hook $1 $2
  _THEME_HOOKS+=$1:$2
}

typeset -g _GIT_BRANCH=${(g::)ZSH_THEME_GIT_ICON_BRANCH}
typeset -g _GIT_COMMIT=${(g::)ZSH_THEME_GIT_ICON_COMMIT}
typeset -g _GIT_GITHUB=${(g::)ZSH_THEME_GIT_ICON_GITHUB}
typeset -g _GIT_GITLAB=${(g::)ZSH_THEME_GIT_ICON_GITLAB}
typeset -g _GIT_SEGMENT=
typeset -g _GIT_TOPLEVEL=
typeset -g _GIT_IGNORED_PWD=
typeset -gi _GIT_IGNORED=0

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
  _GIT_TOPLEVEL=
  return 1
}

_git_ignored() {
  emulate -L zsh
  if [[ $_GIT_IGNORED_PWD != $PWD ]]; then
    command git check-ignore -q . 2>/dev/null
    _GIT_IGNORED=$(( $? == 0 ))
    _GIT_IGNORED_PWD=$PWD
  fi
  (( _GIT_IGNORED ))
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
  [[ -r $config ]] || { : ${(P)1::=}; return 0 }
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
  : ${(P)1::=}
}

_git_segment() {
  emulate -L zsh
  _GIT_SEGMENT=
  _git_in_repo || return 0
  _git_ignored && return 0

  local -a lines
  lines=(${(f)"$(command git --no-optional-locks status --porcelain -b 2>/dev/null)"})
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

  local untracked= modified= deleted= line x y
  for line in ${lines[2,-1]}; do
    x=${line[1]} y=${line[2]}
    if [[ $line == '??'* ]]; then
      untracked=$ZSH_THEME_GIT_PROMPT_UNTRACKED
    elif [[ $x == D || $y == D ]]; then
      deleted=$ZSH_THEME_GIT_PROMPT_DELETED
    elif [[ $x$y == *[MTARCU]* ]]; then
      modified=$ZSH_THEME_GIT_PROMPT_MODIFIED
    fi
    [[ -n $untracked && -n $modified && -n $deleted ]] && break
  done

  local flags=
  [[ $header == *'[behind '* || $header == *', behind '* ]] && flags+=$ZSH_THEME_GIT_PROMPT_BEHIND
  [[ $header == *'[ahead '* ]] && flags+=$ZSH_THEME_GIT_PROMPT_AHEAD
  flags+=${deleted}${modified}${untracked}
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

typeset -g _SQUANCHY_CACHE_DIR=${XDG_CACHE_HOME:-~/.cache}/squanchy
typeset -gi _SQUANCHY_CACHE_TTL=86400

typeset -g _SQUANCHY_RPROMPT=
typeset -gA _SQUANCHY_LOCAL
typeset -ga _SQUANCHY_PROJECT
typeset -g _SQUANCHY_LOCAL_KEY=

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
  : ${(P)1::=}
  return 1
}

_squanchy_refresh() {
  emulate -L zsh
  local file=$1 lock=$1.lock
  local -a st
  shift
  [[ -d $_SQUANCHY_CACHE_DIR ]] || command mkdir -p $_SQUANCHY_CACHE_DIR
  if [[ -d $lock ]]; then
    zstat -A st +mtime -- $lock 2>/dev/null
    (( ${st[1]:-0} + 60 < EPOCHSECONDS )) && command rmdir $lock 2>/dev/null
  fi
  command mkdir $lock 2>/dev/null || return 0
  (
    trap 'command rmdir $lock 2>/dev/null' EXIT
    local tmp=$file.$sysparams[pid]
    if "$@" > $tmp 2>/dev/null && [[ -s $tmp ]]; then
      command mv -f $tmp $file
    else
      command rm -f $tmp
      command touch $file
    fi
  ) &>/dev/null </dev/null &!
}

_squanchy_cache() {
  emulate -L zsh
  local file=$_SQUANCHY_CACHE_DIR/$2 value=
  local -i since=$3
  local -a st
  if [[ -r $file ]]; then
    read -r value < $file
    zstat -A st +mtime -- $file 2>/dev/null
  fi
  : ${(P)1::=${value//$'\r'/}}
  (( ${st[1]:-0} >= since )) && return 0
  shift 3
  (( $# )) && _squanchy_refresh $file "$@"
  return 0
}

_squanchy_lts() {
  emulate -L zsh
  local -a cmd
  (( $+functions[lts] )) && cmd=(lts $2)
  _squanchy_cache $1 lts-$2 $(( EPOCHSECONDS - _SQUANCHY_CACHE_TTL )) $cmd
}

_squanchy_latest() {
  emulate -L zsh
  local -a cmd
  (( $+commands[curl] && $+commands[jq] )) && cmd=(_squanchy_fetch_latest $2)
  _squanchy_cache $1 latest-$2 $(( EPOCHSECONDS - _SQUANCHY_CACHE_TTL )) $cmd
}

_squanchy_fetch_latest() {
  emulate -L zsh
  command curl -fsSL --max-time 2 "https://registry.npmjs.org/$1/latest" | command jq -re .version
}

_squanchy_has_update() {
  emulate -L zsh
  [[ ${1#v} == [0-9]* && ${2#v} == [0-9]* ]] || return 1
  local -a l=(${(s/./)${${1#v}%%[-+]*}}) c=(${(s/./)${${2#v}%%[-+]*}})
  l=("${(@)l%%[^0-9]*}") c=("${(@)c%%[^0-9]*}")
  local -i l1=10#${l[1]:-0} l2=10#${l[2]:-0} l3=10#${l[3]:-0}
  local -i c1=10#${c[1]:-0} c2=10#${c[2]:-0} c3=10#${c[3]:-0}
  (( l1 > c1 || (l1 == c1 && l2 > c2) || (l1 == c1 && l2 == c2 && l3 > c3) ))
}

_squanchy_detect_manager() {
  emulate -L zsh
  local toplevel=$1
  local pkg=$toplevel/package.json
  _SQUANCHY_LOCAL[manager]=
  _SQUANCHY_LOCAL[manager_pinned]=
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
  local toplevel= key=$PWD
  local -a st
  if _git_in_repo && [[ $_GIT_TOPLEVEL != $HOME ]]; then
    toplevel=$_GIT_TOPLEVEL
    zstat -A st +mtime -- $toplevel $toplevel/(.node-version|.ruby-version|.python-version|package.json)(N) 2>/dev/null
    key+=:$toplevel:${(j.:.)st}
  fi
  [[ $_SQUANCHY_LOCAL_KEY == $key ]] && return 0
  _SQUANCHY_LOCAL_KEY=$key
  _SQUANCHY_LOCAL=()
  _SQUANCHY_PROJECT=()
  [[ -n $toplevel ]] || return 0

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

_squanchy_lang_root() {
  emulate -L zsh
  local _root
  case $2 in
    node) _root=${NODENV_ROOT:-~/.nodenv} ;;
    ruby) _root=${RBENV_ROOT:-~/.rbenv} ;;
    python) _root=${PYENV_ROOT:-~/.pyenv} ;;
    *) return 1 ;;
  esac
  : ${(P)1::=$_root}
}

_squanchy_version() {
  emulate -L zsh
  local lang=$2
  local local_version=${_SQUANCHY_LOCAL[$lang]}
  local global_version= lts_version= out= root=
  _squanchy_lang_root root $lang
  [[ -n $root && -r $root/version ]] && _squanchy_first_line global_version $root/version
  _squanchy_lts lts_version $lang

  if [[ -n $local_version ]]; then
    if _squanchy_version_installed $lang $local_version; then
      out=${local_version}${ZSH_THEME_SQUANCHY_ICON_PIN}
      _squanchy_has_update "$lts_version" "$local_version" && out+=$ZSH_THEME_SQUANCHY_ICON_UP
    else
      out=${local_version}${ZSH_THEME_SQUANCHY_ICON_PIN_ALT}
    fi
  elif [[ -z $global_version ]]; then
    out=$ZSH_THEME_SQUANCHY_EMPTY
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
  _squanchy_lang_root root $lang || return 1
  [[ -d $root/versions/$version ]]
}

_squanchy_php() {
  emulate -L zsh
  local bin=$commands[php] ver=
  local -a st
  if [[ -n $bin ]]; then
    zstat -A st +ctime -- $bin 2>/dev/null
    _squanchy_cache ver php-version ${st[1]:-1} _squanchy_fetch_php $bin
  fi
  : ${(P)1::=${ver:+${(j:.:)${(@s:.:)ver}[1,2]}}}
}

_squanchy_fetch_php() {
  emulate -L zsh
  local first=${${(f)"$(command $1 -v 2>/dev/null)"}[1]}
  local -a parts=(${(s/ /)first})
  [[ -n ${parts[2]} ]] && print -r -- ${parts[2]}
}

_squanchy_corepack() {
  emulate -L zsh
  local pm=$2
  local file=${COREPACK_HOME:-${XDG_CACHE_HOME:-~/.cache}/node/corepack}/lastKnownGood.json
  [[ -r $file ]] || { : ${(P)1::=}; return 0 }
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
  local root=${NODENV_ROOT:-~/.nodenv}
  [[ -z $nv && -r $root/version ]] && _squanchy_first_line nv $root/version

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
      local bin=${commands[bun]:-${BUN_INSTALL:-~/.bun}/bin/bun}
      if [[ -x $bin ]]; then
        local ver=
        local -a st
        zstat -A st +ctime -- $bin 2>/dev/null
        _squanchy_cache ver bun-version ${st[1]:-1} $bin --version
        [[ -n $ver ]] && { : ${(P)1::=$ver}; return 0 }
      fi
      ;;
  esac

  : ${(P)1::=}
}

_squanchy_pm_segment() {
  emulate -L zsh
  local pm=$2 corepack=$3 pinned=$4
  local version= latest=

  if [[ -n $pinned ]]; then
    version=$pinned
  else
    _squanchy_pm_version version $pm "$corepack"
  fi
  [[ -z $version ]] && { : ${(P)1::=}; return 1 }

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
    [[ -z $version || $version == $ZSH_THEME_SQUANCHY_EMPTY ]] && continue
    segments+="%{$color%}${icon} ${version}%{$reset_color%}"

    manager=${_SQUANCHY_LOCAL[manager]}
    if [[ $r == node && -n $manager && -n ${_SQUANCHY_PM_ICONS[$manager]} ]]; then
      _squanchy_corepack corepack $manager
      _squanchy_pm_segment pm_seg $manager "$corepack" "${_SQUANCHY_LOCAL[manager_pinned]}" \
        && segments+=$pm_seg
    fi
  done
  _SQUANCHY_RPROMPT=${(j:  :)segments}

  local -i gap=$(( ZSH_THEME_SQUANCHY_GAP > 0 ? ZSH_THEME_SQUANCHY_GAP : 0 ))
  [[ -n $_SQUANCHY_RPROMPT ]] && (( gap )) \
    && _SQUANCHY_RPROMPT=${(l:gap:: :)}${_SQUANCHY_RPROMPT}
}

_squanchy_precmd() {
  _squanchy_resolve_local
  _git_segment
  _squanchy_rprompt
}

_theme_hook precmd _squanchy_precmd

PROMPT='%(?:%{$fg_bold[green]%}$:%{$fg_bold[red]%}$)%{$reset_color%} '
PROMPT+='%1~ '
PROMPT+='${_GIT_SEGMENT}'
RPROMPT='${_SQUANCHY_RPROMPT}'
