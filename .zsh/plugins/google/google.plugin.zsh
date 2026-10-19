google() {
  emulate -L zsh

  case $1 in
    help|-h|--help)
      print -r -- 'Usage: google <query>'
      print -r --
      print -r -- 'Search the given query on Google using the default browser.'
      ;;
    '')
      command open https://google.com
      ;;
    *)
      local LC_ALL=C q='' char hex
      for char in "${(@s::)*}"; do
        case $char in
          [a-zA-Z0-9.~_-]) q+=$char ;;
          ' ') q+='+' ;;
          *)
            printf -v hex '%%%02X' "'$char"
            q+=$hex
            ;;
        esac
      done
      command open "https://google.com/search?q=$q&ie=UTF-8"
      ;;
  esac
}
