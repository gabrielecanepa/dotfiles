#!/bin/zsh

function google () {
  case $1 in
    help|-h|--help)
      echo "Usage: google <query>"
      echo "Open the default browser and search the provided query on Google.com"
      echo
      echo "Commands:"
      echo -e "  help\t\t Print this help message"
      ;;

    *)
      local q="$@"
      open https://google.com/search\?q\=${q// /+}
      ;;
  esac
}
