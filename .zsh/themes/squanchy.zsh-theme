function load_squanchy_theme() {
  ##
  # Returns the given language and version appending a symbol if the version is not the latest.
  # @example `version_prompt node@21.1.0 # => 21.1.0↑`
  ##
  local function version_prompt() {
    local split=(${(s/@/)1})
    local lang="${split[1]}"
    local version="${split[2]}"

    # Return n/a if language or version are not specified.
    [[ -z "$lang" || -z "$version" ]] && echo "n/a" && return 0
    # Return initial version if lts is not installed or version is local.
    ! command -v lts &>/dev/null || \
    ([[ "$lang" == "node" ]] && ([[ -f ".nvmrc" ]] || [[ -f ".node-version" ]])) || \
    ([[ "$lang" == "ruby" ]] && [[ -f ".ruby-version" ]]) || \
    ([[ "$lang" == "python" ]] && [[ -f ".python-version" ]]) && \
    echo "$version" && return 0


    # Split version and lts into parts.
    local version_parts=(${(s/./)version})
    local lts="$(lts "$lang")"
    local lts_parts=(${(s/./)lts})

    if [[ "$version_parts[1]" != "$lts_parts[1]" ]]; then
      local lts="$(lts "$lang@$version_parts[1]")"
      local lts_parts=(${(s/./)lts})
    fi

    if [[ "$lts_parts[2]" -gt "$version_parts[2]" || "$lts_parts[3]" -gt "$version_parts[3]" ]]; then
      echo "$version↑"
      return 0
    fi
    echo "$version"
  }

  # Settings
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
  ZSH_THEME_SQUANCHY_ICON_GITHUB="\\uf7a3"
  ZSH_THEME_SQUANCHY_ICON_NODE="\\ue718"
  ZSH_THEME_SQUANCHY_ICON_PHP="\\ue608"
  ZSH_THEME_SQUANCHY_ICON_PYTHON="\\uf81f"
  ZSH_THEME_SQUANCHY_ICON_RUBY="\\uf43b"

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
    if node -v &>/dev/null; then
      local version="${$(node -v)#v}"
      local node_version=$(version_prompt "node@$version")
    elif [[ -f "./.node-version" ]]; then
      local node_version="${$(cat .node-version)#v} ⚠"
    elif [[ -f "./.nvmrc" ]]; then
      local node_version="${$(cat .nvmrc)#v} ⚠"
    else
      local node_version="n/a"
    fi
    echo "%{$fg[green]%}$ZSH_THEME_SQUANCHY_ICON_NODE $node_version%{$reset_color%}"
  }

  ## Ruby
  local function ruby_prompt() {
    if ruby -v &>/dev/null; then
      local version="$(echo ${(M)$(ruby -v)##[0-9].[0-9].[0-9]})"
      local ruby_version=$(version_prompt "ruby@$version")
    elif [[ -f "./.ruby-version" ]]; then
      local ruby_version="$(cat .ruby-version) ⚠"
    else
      local ruby_version="n/a"
    fi
    echo "%{$fg[red]%}$ZSH_THEME_SQUANCHY_ICON_RUBY $ruby_version%{$reset_color%}"
  }

  ## Python
  local function python_prompt() {
    if python -V &>/dev/null; then
      local version="${$(python -V)#Python }"
      local python_version=$(version_prompt "python@$version")
    elif [[ -f "./.python-version" ]]; then
      local python_version="$(cat .python-version) ⚠"
    else
      local python_version="n/a"
    fi
    echo "%{$fg[yellow]%}$ZSH_THEME_SQUANCHY_ICON_PYTHON $python_version%{$reset_color%}"
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

load_squanchy_theme
unset -f load_squanchy_theme
