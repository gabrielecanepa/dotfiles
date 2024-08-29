function _squanchy() {
  ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}↑"
  ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}↓"
  ZSH_THEME_GIT_PROMPT_CLEAN=""
  ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}*"
  ZSH_THEME_GIT_PROMPT_DIRTY=""
  ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}*"
  ZSH_THEME_GIT_PROMPT_PREFIX=""
  ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
  ZSH_THEME_GIT_PROMPT_UNSTAGED=""
  ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}*"
  ZSH_THEME_SQUANCHY_ICON_BRANCH="\\ue727"
  ZSH_THEME_SQUANCHY_ICON_COMMIT="\\ue729"
  ZSH_THEME_SQUANCHY_ICON_GITHUB="\\uf09b"
  ZSH_THEME_SQUANCHY_ICON_NODE="\\ue718"
  ZSH_THEME_SQUANCHY_ICON_PHP="\\ue608"
  ZSH_THEME_SQUANCHY_ICON_PYTHON="\\ue606"
  ZSH_THEME_SQUANCHY_ICON_RUBY="\\ueb48"

  ##
  # Returns the current version of the specified language.
  # @example `get_version node # => 16.0.0`
  ##
  local function get_version() {
    local lang="$1"
    [[ $lang == "python" ]] && flag="-V" || flag="-v"
    ! $lang $flag &>/dev/null && echo "" && return 1
    case $lang in
      node) echo "${$(node -v)#v}";;
      ruby) [[ "$(ruby -v)" =~ ([0-9].[0-9].[0-9]) ]] && echo $match;;
      python) echo "${$(python -V)#Python }";;
      php) echo "${$(php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3)}";;
    esac
    echo ""
    return 1
  }

  ##
  # Returns the given language and version appending a symbol if the version is not the latest.
  # @example `version_prompt node@21.1.0 # => 21.1.0↑`
  ##
  local function version_prompt() {
    local lang=$1
    local version=$(get_version $lang)

    # Return version with warning if the version is not installed.
    if [[ -z "$version" ]]; then
      version="$(cat ./.${lang}-version 2>/dev/null)"
      [[ -z "$version" ]] && echo "n/a" || echo "$version⚠"
      return 0
    fi

    # Return initial version if `lts` is not installed.
    ! command -v lts &>/dev/null && echo $version && return 0

    local version_parts=(${(s/./)version})
    local lts="$(lts "$lang")"
    local lts_parts=(${(s/./)lts})

    if [[ "$lts_parts[1]" > "$version_parts[1]" || "$lts_parts[2]" > "$version_parts[2]" || "$lts_parts[3]" > "$version_parts[3]" ]]; then
      local has_upgrade=true
    fi

    if [[ "$(pwd)" != "$HOME" && -f "./.${lang}-version" ]]; then
      # Return version with flag if the version is local.
      [[ $has_upgrade == true ]] && local suffix="⚐" || local suffix="⚑"
    else
      # Return version with upgrades.
      [[ $has_upgrade == true ]] && local suffix="↑"
    fi

    echo "$version$suffix"
  }

  ## Git
  local function git_prompt() {
    # Return if current path is not in a git repository or a parent gitignore.
    ! git rev-parse --is-inside-work-tree &>/dev/null || git check-ignore . &>/dev/null && echo "" && return 0
    local git_prompt="%F{202}$ZSH_THEME_SQUANCHY_ICON_BRANCH$(git_prompt_info)%{$reset_color%}$(git_prompt_status)"
    if git config --get remote.origin.url &>/dev/null; then
      echo "$ZSH_THEME_SQUANCHY_ICON_GITHUB$ZSH_THEME_SQUANCHY_ICON_COMMIT$git_prompt "
      return 0
    fi
    echo "$git_prompt "
  }

  ## Node.js
  local function node_prompt() {
    local version_prompt="$(version_prompt node)"
    echo "%{$fg[green]%}$ZSH_THEME_SQUANCHY_ICON_NODE $version_prompt%{$reset_color%}"
  }

  ## Ruby
  local function ruby_prompt() {
    local version_prompt="$(version_prompt ruby)"
    echo "%{$fg[red]%}$ZSH_THEME_SQUANCHY_ICON_RUBY $version_prompt%{$reset_color%}"
  }

  ## Python
  local function python_prompt() {
    local version_prompt="$(version_prompt python)"
    echo "%{$fg[yellow]%}$ZSH_THEME_SQUANCHY_ICON_PYTHON $version_prompt%{$reset_color%}"
  }

  ## PHP
  local function php_prompt() {
    local php_version="$(php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3)"
    echo "%{$fg[blue]%}$ZSH_THEME_SQUANCHY_ICON_PHP $php_version%{$reset_color%}"
  }

  # Left prompt
  PROMPT='%(?:%{$fg_bold[green]%}✓:%{$fg_bold[red]%}✗)%{$reset_color%} ' # status
  PROMPT+='%{$fg[cyan]%}%c%{$reset_color%} ' # current path
  PROMPT+='$(git_prompt)' # git

  # Right prompt
  rprompts=()
  [[ -z "$ZSH_THEME_SQUANCHY_LANGS" ]] && ZSH_THEME_SQUANCHY_LANGS=(node ruby python php)
  for rprompt in $(tr ' ' '\n' <<< "${ZSH_THEME_SQUANCHY_LANGS[@]}" | awk '!u[$0]++' | tr '\n' ' '); do
    case $rprompt in
      node) rprompts+='$(node_prompt)';;
      ruby) rprompts+='$(ruby_prompt)';;
      python) rprompts+='$(python_prompt)';;
      php) rprompts+='$(php_prompt)';;
      *) echo "${fg[red]}Unknown theme prompt: $rprompt$reset_color";;
    esac
  done; unset rprompt
  RPROMPT="${(j:  :)rprompts}"
  unset rprompts
}

_squanchy
unset -f _squanchy
