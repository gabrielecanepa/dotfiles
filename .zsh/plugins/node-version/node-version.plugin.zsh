#!/bin/zsh

function node-version() {
  case $1 in
    dump)
      echo ${$(node -v)#v} > ./.node-version
      ;;
    *)
      if [[ ! -z $1 ]]; then
        echo "Unknown option: $1"
        echo "Usage: node-version [dump]"
        return 1
      fi
      echo ${$(node -v)#v}
      ;;
  esac
}

function node() {
  [[ $1 == -V ]] && node-version || command node $@
}
