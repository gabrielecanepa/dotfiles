_git_shortcuts() {
  add-zsh-hook -d precmd _git_shortcuts
  unfunction _git_shortcuts
  local git_alias prefix=${GIT_SHORTCUTS_PREFIX-g}
  local -i min=${GIT_SHORTCUTS_MIN_LENGTH:-1} max=${GIT_SHORTCUTS_MAX_LENGTH:--1}
  if (( min < 1 )); then
    print -ru2 -- 'git-shortcuts: GIT_SHORTCUTS_MIN_LENGTH must be at least 1'
    return 1
  elif (( max != -1 && max < 2 )); then
    print -ru2 -- 'git-shortcuts: GIT_SHORTCUTS_MAX_LENGTH must be -1 (no limit) or at least 2'
    return 1
  elif (( max != -1 && min > max )); then
    print -ru2 -- 'git-shortcuts: GIT_SHORTCUTS_MIN_LENGTH must not exceed GIT_SHORTCUTS_MAX_LENGTH'
    return 1
  fi
  for git_alias in ${${(f)"$(git config --name-only --get-regexp '^alias\.')"}#alias.}; do
    (( ${GIT_SHORTCUTS_EXCLUDE[(Ie)$git_alias]:-0} )) && continue
    if (( ! ${GIT_SHORTCUTS_INCLUDE[(Ie)$git_alias]:-0} )); then
      (( $#git_alias < min || (max != -1 && $#git_alias > max) )) && continue
    fi
    command -v $prefix$git_alias >/dev/null || alias $prefix$git_alias="git $git_alias"
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _git_shortcuts
