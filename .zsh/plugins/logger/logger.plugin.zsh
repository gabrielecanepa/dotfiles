#
# logger: shared leveled logger (_zsh::log) for the custom plugins. Load before its consumers.
#

# _zsh::log <error|warn|success|info> <plugin> <text>: prints to stderr, colored on a TTY.
_zsh::log() {
  emulate -L zsh
  setopt no_prompt_subst
  local level=$1 plugin=$2 text=$3 color label
  case $level in
    error) color='%F{red}' label='error' ;;
    warn) color='%F{yellow}' label='warning' ;;
    success) color='%F{green}' label='ok' ;;
    info | *) color='%F{blue}' label='info' ;;
  esac
  if [[ -t 2 ]]; then
    # Escape % in caller text so print -P treats it as literal, not a prompt escape.
    print -Pru2 -- "${color}${plugin}%f: ${text//\%/%%}"
  else
    print -ru2 -- "${plugin}: ${label}: ${text}"
  fi
}
