if ! typeset -f _zsh::log >/dev/null; then
  _zsh::log() {
    print -ru2 -- "$2: $3"
  }
fi

typeset -ga ZSH_RUNTIME_MANAGERS
(($#ZSH_RUNTIME_MANAGERS)) || ZSH_RUNTIME_MANAGERS=(nodenv pyenv rbenv)

() {
  emulate -L zsh

  local manager bin root completion
  local -a dirs subcommands

  for manager in $ZSH_RUNTIME_MANAGERS; do
    if ((! ${+commands[$manager]})); then
      _zsh::log warn runtimes "command not found: $manager"
      continue
    fi

    export "${(U)manager}_SHELL=zsh"

    bin=${commands[$manager]}
    root=${(P)${:-${(U)manager}_ROOT}:-$HOME/.$manager}
    dirs=(${bin:A:h} ${bin:A:h:h}/libexec)
    subcommands=(${^dirs}/$manager-sh-*(N:t) "$root/plugins/"*/bin/$manager-sh-*(N:t))
    subcommands=(${(u)${subcommands#$manager-sh-}})
    (($#subcommands)) || subcommands=(rehash shell)

    functions[$manager]="
      local command=\"\${1:-}\"
      (( \$# )) && shift
      case \"\$command\" in
        ${(j:|:)subcommands}) eval \"\$(command $manager \"sh-\$command\" \"\$@\")\" ;;
        *) command $manager \"\$command\" \"\$@\" ;;
      esac
    "

    completion=${bin:A:h:h}/completions/$manager.zsh
    [[ -r "$completion" ]] && builtin source "$completion"
  done
}
