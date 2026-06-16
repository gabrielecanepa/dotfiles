# Search Google in the default browser, or open google.com with no query.
#
# Usage: google <query>

google() {
  emulate -L zsh

  case "$1" in
    help|-h|--help)
      print -r -- "Usage: google <query>"
      print -r --
      print -r -- "Open the default browser and search the given query on Google, or the homepage with no query."
      ;;
    "")
      command open https://google.com
      ;;
    *)
      local q=$*
      command open "https://google.com/search?q=${q// /+}"
      ;;
  esac
}
