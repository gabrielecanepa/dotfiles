![](./banner.png)

> [!WARNING]
> Before using the following dotfiles, you should first fork this repository, review the content and remove things you don’t want or need. **Don’t blindly use my settings** unless you know what you are doing. Use at your own risk!

<!-- no toc -->

<h2>Installation</h2>

- [SSH](#ssh)
- [Homebrew](#homebrew)
- [Oh My Zsh](#oh-my-zsh)
- [Dotfiles](#dotfiles)
- [Shell profile](#shell-profile)
- [Runtimes and dependencies](#runtimes-and-dependencies)
  - [Node.js](#nodejs)
  - [Ruby](#ruby)
  - [Python](#python)
- [VSCode and terminal](#vscode-and-terminal)
  - [Settings and snippets](#settings-and-snippets)
  - [Keybindings](#keybindings)
- [Assets](#assets)
  - [Fonts](#fonts)
  - [iCloud](#icloud)

### SSH

If not already present, generate a new SSH key and copy it to the clipboard:

```sh
ssh-keygen -t ed25519 -C "<comment>"
tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
```

Add the key to [GitHub](https://github.com/settings/ssh/new), [GitLab](https://gitlab.com/-/profile/keys) and any other services you use.

### Homebrew

Install [Homebrew](https://brew.sh):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Oh My Zsh

Install [Oh My Zsh](https://ohmyz.sh) and some useful plugins from [zsh-users](https://github.com/zsh-users):

```sh
/bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"

plugins=(
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

for plugin in ${plugins[@]}; do
  git clone https://github.com/zsh-users/${plugin}.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${plugin}
done

# Restart
zsh
```

### Dotfiles

Clone this repository:

```sh
gh repo clone gabrielecanepa/dotfiles
# or
git clone git@github.com:gabrielecanepa/dotfiles.git
```

Copy the files to your home directory, manually or in bulk.

> [!WARNING]
> The following bulk operation will overwrite all existing files in your home directory. Existing files will be backed up in `~/.bak`.

```sh
cd dotfiles
bak=$(mkdir -p ~/.bak/dotfiles/$(date +%Y%m%d) && echo $_)

for config in $(ls -A); do
  [[ -e ~/$config ]] && cp -fr ~/$config $bak
  cp -fr $config ~/$config
done
```

Install the packages listed in the [Brewfile](/.Brewfile):

```sh
brew bundle --file ~/.Brewfile
```

### Shell profile

Use the custom [`profile` plugin](/.zsh/plugins/profile/profile.plugin.zsh) to create your shell profile with a guided prompt:

```sh
profile install
```

### Runtimes and dependencies

#### Node.js

Install the [Node.js](https://nodejs.org) version in use with [nodenv](https://github.com/nodenv/nodenv):

```sh
nodenv install $(cat ~/.node_version) --skip-existing
```

Install the global npm dependencies listed in the global `package.json`, enable [Corepack](https://github.com/nodejs/corepack) and initialize [Husky](https://typicode.github.io/husky):

```sh
npm -g install $(jq -r '.dependencies | keys | join(" ")' ~/.npm/package.json)
corepack enable
husky
```

Link the local nodenv version to the tracked one:

```sh
nodenv global $(cat ~/.node-version)
rm -f $NODENV_ROOT/version && ln -sf ~/.node-version $NODENV_ROOT/version
```

Link the global Bun and pnpm files to the tracked ones:

```sh
# Bun
for file in bun.lockb package.json; do
  rm -f $BUN_HOME/install/global/$file
  ln -sf ~/.bun/$file $BUN_HOME/install/global/$file
done

# pnpm
for file in package.json pnpm-lock.yaml; do
  rm -f $PNPM_HOME/5/$file
  ln -sf ~/.pnpm/$file $PNPM_HOME/5/$file
done
```

#### Ruby

Install and link the [Ruby](https://ruby-lang.org) version in use with [rbenv](https://github.com/rbenv/rbenv):

```sh
rbenv install $(cat ~/.ruby-version) --skip-existing
rm -f $RBENV_ROOT/version && ln -sf ~/.ruby-version $RBENV_ROOT/version
```

#### Python

Install and link the [Python](https://python.org) version in use with [pyenv](https://github.com/pyenv/pyenv):

```sh
pyenv install $(cat ~/.python-version) --skip-existing
rm -f $PYENV_ROOT/version && ln -sf ~/.python-version $PYENV_ROOT/version
```

### VSCode and terminal

#### Settings and snippets

Use symlinks to backup keybindings, settings and snippets of [Visual Studio Code](https://code.visualstudio.com) and [iTerm2](https://iterm2.com).

> [!WARNING]
> The following operations will permanently replace some system folders with symlinks to the corresponding files in the repository. Make sure to back up your data before proceeding.

```sh
# VSCode
for config in prompts snippets keybindings.json mcp.json settings.json; do
  file=~/Library/Application\ Support/Code/User/$config
  rm -rf $file
  ln -sf ~/.vscode/user/$config $file
done

# iTerm
rm -rf ~/.config/iterm2/AppSupport/DynamicProfiles
ln -sf ~/.config/iterm2/profiles ~/.config/iterm2/AppSupport/DynamicProfiles
```

#### Keybindings

To avoid emitting beeps in Electron-based applications when using the keyboard combinations `^⌘←`, `^⌘↓` and `^⌘` (see [this issue](https://github.com/electron/electron/issues/2617)) create the keybinding settings file:

```sh
[[ ! -d ~/Library/KeyBindings ]] && mkdir ~/Library/KeyBindings
touch ~/Library/KeyBindings/DefaultKeyBinding.dict
```

And populate it with the following content:

```
{
  "^@\UF701" = "noop";
  "^@\UF702" = "noop";
  "^@\UF703" = "noop";
}
```

### Assets

#### Fonts

To display icons in your terminal, download a font supporting [Nerd Fonts](https://nerdfonts.com), like [Monaco](https://github.com/Karmenzind/monaco-nerd-fonts/tree/master/fonts). Activate the fonts in apps supporting command line interfaces (Terminal, Ghostty, VSCode, etc).

#### iCloud

Use the following script to:

- Replace the home `Downloads`, `Movies` and `Music` folders with a symbolic link to the corresponding (new or existing) folder on iCloud. This grants continuous synchronization between the cloud and your local machine.
- Replace the home `Applications` folder with a symlink to the system applications folder.
- Create a symlink named `iCloud`, pointing to the related cloud folder, in `Applications`, `Developer` and `Pictures`.

> [!WARNING]
> The following operations will permanently replace some system folders with symbolic links to iCloud Drive. Make sure to back up your data before proceeding.

<br>

```sh
for folder in Applications Developer Downloads Movies Music Pictures; do
  # Create the folder in iCloud Drive
  cloud_folder=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
  [[ ! -d $cloud_folder ]] && mkdir $cloud_folder

  case $folder in
    # Replace with a symlink to the system folder
    Applications)
      rm -rf ~/Applications
      ln -sf /Applications ~/Applications
      ln -sf $cloud_folder /Applications/iCloud
      ;;
    # Create a symlink named iCloud
    Developer|Pictures)
      ln -sf $cloud_folder ~/$folder/iCloud
      ;;
    # Replace with a symlink to the cloud folder
    Downloads|Movies|Music)
      [[ -d ~/$folder ]] && mv ~/$folder/* $cloud_folder 2>/dev/null
      rm -rf ~/$folder && ln -sf $cloud_folder ~/$folder
      ;;
  esac
done
```

The icons of the generated symlink can be manually replaced with any of the available system icons:

```sh
open /System/Library/Extensions/IOStorageFamily.kext/Contents/Resources
```
