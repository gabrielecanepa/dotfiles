#!/usr/bin/env bash

set -euo pipefail

REPO="gabrielecanepa/dotfiles"
BREWFILE="$HOME/.homebrew/Brewfile"
MACOS_DEFAULTS="$HOME/.macos"
CODEX_CONFIG="$HOME/.codex/config.toml"
CODEX_CONFIG_SYSTEM="/etc/codex/config.toml"
CODEX_CONFIG_SHARED="$HOME/.codex/settings.toml"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backup/$TIMESTAMP"

skipped=()
failed=()

info() {
  printf '\033[1;34m==>\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m  !\033[0m %s\n' "$1" >&2
}

backup() {
  rel="$1"
  current="$2"
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$current" "$BACKUP_DIR/$rel"
}

confirm() {
  { : </dev/tty; } 2>/dev/null || {
    warn "No terminal to prompt on, skipping"
    return 1
  }
  local reply=""
  read -r -p "$1 [y/N] " reply </dev/tty
  case "$reply" in
    [yY]*) return 0 ;;
    *) return 1 ;;
  esac
}

install_file() {
  rel="$1"
  src="$TMP_DIR/$rel"
  dest="$HOME/$rel"
  mkdir -p "$(dirname "$dest")" || {
    failed+=("$rel")
    return 0
  }
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if ! confirm "Overwrite $dest?"; then
      skipped+=("$rel")
      return 0
    fi
    backup "$rel" "$dest" || {
      failed+=("$rel")
      return 0
    }
  fi
  mv "$src" "$dest" || {
    failed+=("$rel")
    return 0
  }
}

# 1. Repository
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.$TIMESTAMP.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
info "Cloning $REPO"
git clone --depth 1 "https://github.com/$REPO.git" "$TMP_DIR"

# 2. Files
info "Installing dotfiles into $HOME"
while IFS= read -r -d '' file; do
  install_file "$file"
done < <(git -C "$TMP_DIR" -c core.quotePath=false ls-files -z)
if [ ${#skipped[@]} -gt 0 ]; then info "skipped ${#skipped[@]} file(s), kept existing"; fi
if [ ${#failed[@]} -gt 0 ]; then warn "failed  ${#failed[@]} file(s): ${failed[*]}"; fi

# 3. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
if [ -f "$BREWFILE" ]; then
  info "Installing packages from $BREWFILE"
  brew bundle --file "$BREWFILE" || failed+=("brew bundle")
fi

# 4. Oh My Zsh + plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh"
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)" || failed+=("oh-my-zsh")
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.zsh}"
for plugin in zsh-users/zsh-autosuggestions zsh-users/zsh-completions zsh-users/zsh-syntax-highlighting wbingli/zsh-claudecode-completion; do
  zsh_plugin="$ZSH_CUSTOM/plugins/${plugin##*/}"
  [ -d "$zsh_plugin" ] || git clone --depth=1 "https://github.com/$plugin.git" "$zsh_plugin" || failed+=("plugin:${plugin##*/}")
done

# 5. Shell profile
info "If this is a new profile, run 'profile install' in an interactive shell"

# 6. Runtimes from .*-version
install_runtime() {
  manager="$1"
  version_file="$2"
  command -v "$manager" >/dev/null 2>&1 || return 0
  [ -f "$HOME/$version_file" ] || return 0
  version="$(cat "$HOME/$version_file")"
  info "$manager install $version"
  "$manager" install "$version" --skip-existing
  "$manager" global "$version"
}
install_runtime nodenv .node-version
install_runtime pyenv .python-version
install_runtime rbenv .ruby-version

# 7. npm + corepack
if command -v npm >/dev/null 2>&1 && [ -f "$HOME/.npm/package.json" ]; then
  info "Installing global npm dependencies"
  deps="$(jq -r '.dependencies // {} | keys | join(" ")' "$HOME/.npm/package.json")"
  if [ -n "$deps" ]; then
    # shellcheck disable=SC2086
    npm -g install $deps || failed+=("npm globals")
  fi
  command -v corepack >/dev/null 2>&1 && corepack enable
fi

# 8. macOS defaults
if [ "$(uname)" = "Darwin" ] && [ -x "$MACOS_DEFAULTS" ]; then
  info "Applying macOS defaults"
  "$MACOS_DEFAULTS" || warn "macOS defaults step failed"
fi

# 9. Codex
if [ -f "$CODEX_CONFIG_SHARED" ]; then
  info "Setting up Codex configuration"
  if [ -L "$CODEX_CONFIG" ] || { [ -e "$CODEX_CONFIG" ] && [ ! -f "$CODEX_CONFIG" ]; }; then
    warn "Codex config must be a regular file: $CODEX_CONFIG"
    failed+=("Codex config")
  elif ! mkdir -p "$(dirname "$CODEX_CONFIG")" || ! touch "$CODEX_CONFIG" || ! chmod 600 "$CODEX_CONFIG"; then
    warn "Failed to prepare Codex config at $CODEX_CONFIG"
    failed+=("Codex config")
  fi

  if [ -e "$CODEX_CONFIG_SYSTEM" ] && [ ! -f "$CODEX_CONFIG_SYSTEM" ] && [ ! -L "$CODEX_CONFIG_SYSTEM" ]; then
    warn "Codex system config must be a file or symlink: $CODEX_CONFIG_SYSTEM"
    failed+=("Codex system config")
  elif [ -L "$CODEX_CONFIG_SYSTEM" ] && [ "$(readlink "$CODEX_CONFIG_SYSTEM")" = "$CODEX_CONFIG_SHARED" ]; then
    info "Codex system config already linked"
  elif { [ ! -e "$CODEX_CONFIG_SYSTEM" ] && [ ! -L "$CODEX_CONFIG_SYSTEM" ]; } || confirm "Replace '$CODEX_CONFIG_SYSTEM' with a symlink?"; then
    if ! sudo mkdir -p "$(dirname "$CODEX_CONFIG_SYSTEM")" || ! sudo ln -sfn "$CODEX_CONFIG_SHARED" "$CODEX_CONFIG_SYSTEM"; then
      warn "Failed to link Codex system config"
      failed+=("Codex system config")
    fi
  else
    skipped+=("Codex system config")
  fi
fi

# 10. Visual Studio Code
if [ "$(uname)" = "Darwin" ]; then
  VSCODE_USER="$HOME/Library/Application Support/Code/User"
  if [ -d "$VSCODE_USER" ]; then
    info "Setting up Visual Studio Code"
    # First-time symlink; `dotfiles init` re-asserts settings.json if Code clobbers it later.
    for config in prompts snippets keybindings.json settings.json; do
      if [ -e "$HOME/.vscode/user/$config" ]; then
        if [ -e "$VSCODE_USER/$config" ] || [ -L "$VSCODE_USER/$config" ]; then
          confirm "Replace '$VSCODE_USER/$config' with a symlink?" || continue
          rm -rf "$VSCODE_USER/$config"
        fi
        ln -sf "$HOME/.vscode/user/$config" "$VSCODE_USER/$config"
      fi
    done
    # Electron beep fix
    KEYBINDINGS_DIR="$HOME/Library/KeyBindings"
    KEYBINDINGS_FILE="$KEYBINDINGS_DIR/DefaultKeyBinding.dict"
    if [ ! -f "$KEYBINDINGS_FILE" ] || confirm "Overwrite '$KEYBINDINGS_FILE' (Electron keyboard beep fix)?"; then
      mkdir -p "$KEYBINDINGS_DIR"
      cat >"$KEYBINDINGS_FILE" <<'EOF'
{
  "^@\UF701" = "noop";
  "^@\UF702" = "noop";
  "^@\UF703" = "noop";
}
EOF
    fi
  fi
fi

# 11. iCloud
if [ "$(uname)" = "Darwin" ]; then
  ICLOUD_DRIVE="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
  if [ -d "$ICLOUD_DRIVE" ]; then
    info "Setting up iCloud Drive symlinks"
    for folder in Downloads Movies Music; do
      cloud_folder="$ICLOUD_DRIVE/$folder"
      relative_folder="${cloud_folder#"$HOME"/}"
      [ "$(readlink "$HOME/$folder")" = "$relative_folder" ] && continue
      confirm "Replace ~/$folder with a symlink to iCloud Drive (existing files will be moved)?" || continue
      mkdir -p "$cloud_folder"
      shopt -s dotglob nullglob
      entries=("$HOME/$folder"/*)
      shopt -u dotglob nullglob
      if [ ${#entries[@]} -gt 0 ] && ! mv "${entries[@]}" "$cloud_folder/"; then
        warn "Failed to move ~/$folder contents to iCloud, leaving it untouched"
        failed+=("$folder")
        continue
      fi
      rm -rf "$HOME/$folder"
      ln -sf "$relative_folder" "$HOME/$folder"
    done
  else
    warn "iCloud Drive not found, skipping setup"
  fi
fi

# 12. Git repository (new machine)
if [ ! -d "$HOME/.git" ]; then
  info "Home directory is not a git repo, initialize it after adding your SSH key (see README §Git):"
  printf '  git -C ~ init -b main\n'
  printf '  git -C ~ remote add origin git@github.com:gabrielecanepa/dotfiles.git\n'
  printf '  git -C ~ fetch --depth 1 origin main && git -C ~ reset --hard FETCH_HEAD\n'
fi

if [ ${#failed[@]} -gt 0 ]; then
  warn "Installation finished with ${#failed[@]} error(s), review the warnings above."
else
  info "Installation complete."
fi
