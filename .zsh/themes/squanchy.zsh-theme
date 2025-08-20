autoload -U colors && colors

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
ZSH_THEME_SQUANCHY_RPROMPT_EMPTY="n/a"
ZSH_THEME_SQUANCHY_ICON_BRANCH="\\ue727"
ZSH_THEME_SQUANCHY_ICON_COMMIT="\\ue729"
ZSH_THEME_SQUANCHY_ICON_GITHUB="\\uf09b"
ZSH_THEME_SQUANCHY_ICON_NODE="\\ue718"
ZSH_THEME_SQUANCHY_ICON_PHP="\\ue608"
ZSH_THEME_SQUANCHY_ICON_PYTHON="\\ue606"
ZSH_THEME_SQUANCHY_ICON_RUBY="\\ueb48"
ZSH_THEME_SQUANCHY_ICON_UP="↑"
ZSH_THEME_SQUANCHY_ICON_PIN="⚑"
ZSH_THEME_SQUANCHY_ICON_PIN_ALT="⚐"

function squanchy() {
  if [[ -z "$ZSH_THEME_RPROMPTS" ]]; then 
    ZSH_THEME_RPROMPTS=(node ruby python php)
  fi

  ##
  # Prints the version manager used for the specified language.
  #
  # @example `get_version_manager node # => nodenv`
  # @example `get_version_manager python # => pyenv`
  ##
  local function get_version_manager() {
    case $1 in
      node) echo "nodenv" ;;
      python) echo "pyenv" ;;
      ruby) echo "rbenv" ;;
      *) return 1 ;;
    esac
  }

  ##
  # Prints the current version of the specified language.
  #
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
  # Prints the given language and version appending symbols to indicate the status.
  #
  # @example `version_prompt node@21.1.0 # => 21.1.0↑`
  ##
  local function version_prompt() {
    local lang=$1
    local version_manager=$(get_version_manager $lang)
    local global_version="$($version_manager global 2>/dev/null)"
    local local_version=""
    local global_version_parts=(${(s/./)global_version})
    local lts_version="$(lts "$lang")"
    local lts_version_parts=(${(s/./)lts_version})
    local has_update=false

    if [[ "$lts_version_parts[1]" > "$global_version_parts[1]" || "$lts_version_parts[2]" > "$global_version_parts[2]" || "$lts_version_parts[3]" > "$global_version_parts[3]" ]]; then
      has_update=true
    fi

    # Local version #
    if [ "$(git rev-parse --show-toplevel 2>/dev/null)" != "$HOME" ]; then
      local local_version="$(cat "$(git rev-parse --show-toplevel 2>/dev/null)/.$lang-version" 2>/dev/null)"
      if [ -n "$local_version" ]; then
        if $version_manager versions | grep -q $local_version; then
          echo "${local_version}$ZSH_THEME_SQUANCHY_ICON_PIN$([[ $has_update == true ]] && echo $ZSH_THEME_SQUANCHY_ICON_UP)"
        else
          echo "${local_version}$ZSH_THEME_SQUANCHY_ICON_PIN_ALT"
        fi
        return 0
      fi
    fi

    ## Global version ##
    
    # Display the empty rprompt if global version is not set
    if [ -z "$global_version" ]; then
      echo $ZSH_THEME_SQUANCHY_RPROMPT_EMPTY
      return 0
    fi

    # Show global version if lts is not installed
    if ! command -v lts &>/dev/null; then
      echo "$global_version"
      return 0
    fi

    # Show global version with warning if global version is not the latest
    local global_version_parts=(${(s/./)global_version})
    local lts_version="$(lts "$lang")"
    local lts_version_parts=(${(s/./)lts_version})

    if [[ "$lts_version_parts[1]" > "$global_version_parts[1]" || "$lts_version_parts[2]" > "$global_version_parts[2]" || "$lts_version_parts[3]" > "$global_version_parts[3]" ]]; then
      echo "${global_version}↑"
      return 0
    fi

    # Default to global version
    echo $global_version
  }

  ## Git
  local function git_prompt() {
    # Return if the current path not in a git repository or ignored
    if ! git rev-parse --is-inside-work-tree &>/dev/null || git check-ignore . &>/dev/null; then 
      echo ""
      return 0
    fi
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
  [[ -z "$ZSH_THEME_RPROMPTS" ]] && ZSH_THEME_RPROMPTS=(node ruby python php)
  for rprompt in $(tr ' ' '\n' <<< "${ZSH_THEME_RPROMPTS[@]}" | awk '!u[$0]++' | tr '\n' ' '); do
    case $rprompt in
      node) rprompts+='$(node_prompt)';;
      ruby) rprompts+='$(ruby_prompt)';;
      python) rprompts+='$(python_prompt)';;
      php) rprompts+='$(php_prompt)';;
      *) echo "${fg[red]}Unknown theme prompt: $rprompt$reset_color";;
    esac
  done
  RPROMPT="${(j:  :)rprompts}"
  unset rprompt rprompts
}

squanchy
