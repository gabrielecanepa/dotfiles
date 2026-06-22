#!/bin/bash

set -euo pipefail

REPO="gabrielecanepa/dotfiles"
BREWFILE="$HOME/.homebrew/Brewfile"
MACOS_DEFAULTS="$HOME/.macos"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backup/$TIMESTAMP"
SKIPPED=()
FAILED=()

info() {
  printf '\033[1;34m==>\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m  !\033[0m %s\n' "$1" >&2
}

backup() {
  rel="$1"; current="$2"
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$current" "$BACKUP_DIR/$rel"
}

confirm() {
  { : < /dev/tty; } 2>/dev/null || { warn "No terminal to prompt on, skipping"; return 1; }
  local reply=""
  read -r -p "$1 [y/N] " reply < /dev/tty
  case "$reply" in
    [yY]*) return 0 ;;
    *) return 1 ;;
  esac
}

install_file() {
  rel="$1"
  src="$TMP_DIR/$rel"
  dest="$HOME/$rel"
  mkdir -p "$(dirname "$dest")" || { FAILED+=("$rel"); return 0; }
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if ! confirm "Overwrite $dest?"; then
      SKIPPED+=("$rel")
      return 0
    fi
    backup "$rel" "$dest" || { FAILED+=("$rel"); return 0; }
  fi
  mv "$src" "$dest" || { FAILED+=("$rel"); return 0; }
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
if [ ${#SKIPPED[@]} -gt 0 ]; then info "Skipped ${#SKIPPED[@]} file(s), kept existing"; fi
if [ ${#FAILED[@]} -gt 0 ];  then warn "Failed  ${#FAILED[@]} file(s): ${FAILED[*]}"; fi

# 3. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# 4. Packages
if [ -f "$BREWFILE" ]; then
  info "Installing packages from $BREWFILE"
  brew bundle --file "$BREWFILE"
fi

# 5. Oh My Zsh + plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh"
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.zsh}"
for plugin in zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
  zsh_plugin="$ZSH_CUSTOM/plugins/$plugin"
  [ -d "$zsh_plugin" ] || git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$zsh_plugin"
done

# 6. Shell profile
info "If this is a new profile, run 'profile install' in an interactive shell"

# 7. Runtimes from .*-version
install_runtime() {
  manager="$1"; version_file="$2"
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

# 8. npm + corepack
if command -v npm >/dev/null 2>&1 && [ -f "$HOME/.npm/package.json" ]; then
  info "Installing global npm dependencies"
  deps="$(jq -r '.dependencies // {} | keys | join(" ")' "$HOME/.npm/package.json")"
  # shellcheck disable=SC2086
  [ -n "$deps" ] && npm -g install $deps
  command -v corepack >/dev/null 2>&1 && corepack enable
fi

# 9. macOS defaults
if [ "$(uname)" = "Darwin" ] && [ -x "$MACOS_DEFAULTS" ]; then
  info "Applying macOS defaults"
  . "$MACOS_DEFAULTS"
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
      cat > "$KEYBINDINGS_FILE" << 'EOF'
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
    for folder in Applications Developer Downloads Movies Music Pictures; do
      cloud_folder="$ICLOUD_DRIVE/$folder"
      case "$folder" in
        Applications)
          confirm "Replace ~/Applications with a symlink to /Applications and link iCloud Drive?" || continue
          mkdir -p "$cloud_folder"
          rm -rf "$HOME/Applications"
          ln -sf /Applications "$HOME/Applications"
          ln -sf "$cloud_folder" /Applications/iCloud
          ;;
        Developer|Pictures)
          confirm "Create ~/$folder/iCloud symlink pointing to iCloud Drive?" || continue
          mkdir -p "$cloud_folder"
          ln -sf "$cloud_folder" "$HOME/$folder/iCloud"
          ;;
        Downloads|Movies|Music)
          confirm "Replace ~/$folder with a symlink to iCloud Drive (existing files will be moved)?" || continue
          mkdir -p "$cloud_folder"
          mv "$HOME/$folder"/* "$cloud_folder/" 2>/dev/null || true
          rm -rf "$HOME/$folder"
          ln -sf "$cloud_folder" "$HOME/$folder"
          ;;
      esac
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

if [ ${#FAILED[@]} -gt 0 ]; then
  warn "Installation finished with ${#FAILED[@]} error(s), review the warnings above."
else
  info "Installation complete."
fi
