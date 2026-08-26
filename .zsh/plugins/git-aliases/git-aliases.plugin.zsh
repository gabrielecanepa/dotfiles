(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

_git_aliases() {
  add-zsh-hook -d precmd _git_aliases
  unfunction _git_aliases
  local git_alias prefix=${ZSH_GIT_ALIASES_PREFIX-g}
  local -i min=${ZSH_GIT_ALIASES_MIN_LENGTH:-1} max=${ZSH_GIT_ALIASES_MAX_LENGTH:--1}
  if (( min < 1 )); then
    _zsh::log error git-aliases "ZSH_GIT_ALIASES_MIN_LENGTH must be at least 1"
    return 1
  elif (( max != -1 && max < 2 )); then
    _zsh::log error git-aliases "ZSH_GIT_ALIASES_MAX_LENGTH must be -1 (no limit) or at least 2"
    return 1
  elif (( max != -1 && min > max )); then
    _zsh::log error git-aliases "ZSH_GIT_ALIASES_MIN_LENGTH must not exceed ZSH_GIT_ALIASES_MAX_LENGTH"
    return 1
  fi
  for git_alias in ${${(f)"$(git config --name-only --get-regexp '^alias\.')"}#alias.}; do
    (( $#git_alias < min || (max != -1 && $#git_alias > max) )) && continue
    [[ -n ${ZSH_GIT_ALIASES_IGNORE[(r)$git_alias]} ]] && continue
    command -v "$prefix$git_alias" >/dev/null || alias "$prefix$git_alias"="git $git_alias"
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _git_aliases
