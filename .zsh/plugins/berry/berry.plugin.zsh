#!/bin/zsh

alias yarn=/opt/homebrew/bin/yarn

function berry() {
  local berry_bin=${"$(type -a yarn | grep "Caches" | head -n 1)"//yarn is /}
  local berry_config=~/.yarn/berry
  local berry_tmp=$berry_config/.zsh-plugin.tmp

  if [[ -z "$berry_bin" ]]; then
    echo "Wrong yarn executable: $berry_bin"
    return 1
  fi

  if [[ ! -d "$berry_config" ]]; then
    mkdir -p "$berry_config"
  fi

  eval "$berry_bin $@" > $berry_tmp
  local exit_code=$?
  cat $berry_tmp | sed "s/yarn/berry/g"
  rm $berry_tmp

  if [[ $1 == "init" ]] && [[ $exit_code == 0 ]]; then
    rm -rf .gitattributes .gitignore
    echo "yarn/" >> .gitignore
    echo ".pnp.*" >> .gitignore
  fi

  return $exit_code
}
