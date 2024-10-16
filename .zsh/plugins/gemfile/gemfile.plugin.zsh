#!/bin/zsh

function gem() {
  local GEMFILE="$HOME/.bundle/Gemfile"
  local GEM_SOURCE="https://rubygems.org"

  local cmd="$1"
  local args=(${@:2})
  local exit=0

  local args_error="ERROR:  While executing gem ... (Gem::CommandLineError)
    The $cmd command does not accept any arguments (Gem::CommandLineError)"

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

    install|uninstall)
      [[ $cmd == "install" && -z "$args" ]] && command gem install $(_leaves) || command gem $@
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

  case $cmd in
    global|install|local|uninstall)
      command rbenv $@
      exit=$?
      ((gem install) >/dev/null &) >/dev/null
      return $exit
      ;;
    *)
      command rbenv $@
      ;;
  esac
}
