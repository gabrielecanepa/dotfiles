#!/bin/zsh

function gem() {
  [[ -z "$GEMFILE" ]] && local GEMFILE="$HOME/.bundle/Gemfile"
  local GEM_SOURCE="https://rubygems.org"

  local cmd="$1"
  local args=(${@:2})
  local exit=0

  local args_error="ERROR:  While executing gem ... (Gem::CommandLineError)
    The $cmd command does not accept any arguments (Gem::CommandLineError)"

  local function _global() {
    cat $GEMFILE | tail -n +3 | sed "s/gem \"//" | sed "s/\"//"
  }

  local function _leaves() {
    local gems=($(command gem list -l | sed "s/ (.*//" | sort))
    local deps=($(echo $gems | xargs -n1 gem dependency -l --pipe | sed "s/ --version.*//" | sort -u))
    echo ${(@)gems:|deps}
  }

  case $cmd in
    dump)
      if [[ ! -z $args ]]; then
        echo $args_error
        return 1
      fi

      local gems=($(_leaves))
      local content="source \"$GEM_SOURCE\"\n\n"
      for gem in $gems; do content+="gem \"$gem\"\n"; done

      echo -e "${content::-2}" > $GEMFILE
      ;;

    leaves)
      [[ ! -z $args ]] && echo $args_error && return 1
      _leaves
      ;;

    global)
      [[ ! -z $args ]] && echo $args_error && return 1
      _global
      ;;

    install|uninstall)
      if [[ $cmd == "install" && -z "$args" ]]; then
        command gem install $(_leaves)
      else
        command gem $@
      fi
      local exit=$?
      ((gem dump) >/dev/null &) >/dev/null
      return $exit
      ;;

    *)
      command gem $cmd $args
      ;;
  esac
}

function rbenv() {
  local cmd="$1"
  local arg="$2"

  local _install_gems() {
    ((gem install >/dev/null) >/dev/null &) >/dev/null
  }

  case $cmd in
    global|install|local|uninstall)
      command rbenv $@
      local exit=$?
      [[ "$arg" =~ ^[0-9]\.[0-9]\.[0-9]$ ]] && _install_gems
      return $exit
      ;;
    *)
      command rbenv $@
      ;;
  esac
}
