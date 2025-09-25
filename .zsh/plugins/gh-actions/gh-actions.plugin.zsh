#!/bin/zsh

function gh () {
  case $1 in
    run)
      case $2 in
        clear)
          local runs=($(gh run list --json databaseId  -q '.[].databaseId' ${@:3}))
          local repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
          local msg="${fg_bold[green]}?$reset_color Are you sure you want to delete ${#runs[@]} workflow run$([[ ${#runs[@]} > 1 ]] && echo "s")? (Y/n) "
          local run=
          local choice=

          echo -n $msg
          read -k1 -r choice

          while [[ ! -z "$(echo -n "$choice" | tr -dc '[:print:]')" && ! "$choice" =~ [yYnN] ]]; do
            echo -e "\n\e[1A\e[K${fg[red]}X Sorry, your reply was invalid: \"$choice\" is not a valid answer, please try again.${reset_color}"
            echo -n $msg
            read -k1 choice
          done

          [[ "$choice" =~ [nN] ]] && echo && return 0

          command gh run delete ${runs[1]} >/dev/null
          [[ ! -z "$(echo -n "$choice" | tr -dc '[:print:]')" ]] && echo
          echo -n "${fg[green]}✓${reset_color} Request to delete workflow run submitted."

          [[ ${#runs[@]} == 1 ]] && echo && return 0

          local count=2

          for run in ${runs[@]:1}; do
            if command gh run delete $run >/dev/null; then
              echo
              echo -e -n "\e[1A\e[K${fg[green]}✓${reset_color} Request to delete $count workflow runs submitted."
              ((count++))
            fi
          done
          echo
          ;;
        *)
          command gh run "${@:2}"
          ;;
      esac
      ;;
    *)
      command gh "$@"
      ;;
  esac
}
