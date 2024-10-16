## Installation

> [!WARNING]
> If you want to try the following dotfiles, you should first fork this repository, review the code and remove things you don’t want or need. **Don’t blindly use my settings** unless you know what you are doing. Use at your own risk!

<!-- no toc -->
1. [SSH](#1-ssh)
2. [Homebrew](#2-homebrew)
3. [Oh My Zsh](#3-oh-my-zsh)
4. [Dotfiles](#4-dotfiles)
5. [Configuration](#5-configuration)
    - [Shell profile](#shell-profile)
6. [Languages and dependencies](#6-languages-and-dependencies)
    - [Node.js](#nodejs)
    - [Ruby](#ruby)
    - [Python](#python)
7. [VSCode](#7-vscode)
    - [Settings, snippets and extensions](#settings-snippets-and-extensions)
    - [Keybindings](#keybindings)
8. [Resources](#8-resources)
   - [Fonts](#fonts)
   - [iCloud](#icloud)

### 1. SSH

If not already present, generate a new SSH key and copy it to the clipboard:

```sh
ssh-keygen -t ed25519 -C "<comment>"
tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
```

Add the key to [GitHub](https://github.com/settings/ssh/new), [GitLab](https://gitlab.com/-/profile/keys) and any other services you use.

### 2. Homebrew

Install [Homebrew](https://brew.sh):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Oh My Zsh

Install [Oh My Zsh](https://ohmyz.sh) and some essential plugins from [zsh-users](https://github.com/zsh-users):

```sh
/bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"

for plugin in zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
  git clone https://github.com/zsh-users/${plugin}.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${plugin}
done

# Restart the shell.
zsh
```

### 4. Dotfiles

Clone this repository:

```sh
git clone git@github.com:gabrielecanepa/dotfiles.git
```

And copy all files to your home directory, manually or in bulk:

> [!WARNING]
> The following bulk operation will overwrite all existing files in your home directory. Existing files will be backed up in `~/.bak`.

```sh
cd dotfiles

bak=$(mkdir -p ~/.bak/dotfiles/$(date +%Y%m%d) && echo $_)

for config in $(ls -A); do
  [[ -e ~/$config ]] && cp -fr ~/$config $bak
  cp -fr $config ~/$config
done

cd ..
rm -rf dotfiles
```

Install all the packages listed in the [Brewfile](/.Brewfile):

```sh
brew bundle --file ~/.Brewfile
```

### 5. Configuration

#### Shell profile

Use the custom [`profile` plugin](/.zsh/plugins/profile/profile.plugin.zsh) to create your shell profile using a guided prompt:

```sh
profile install
```

#### Environment variables

Copy the `.env.example` file to `.env` and fill in the environment-specific values you need:

```sh
cp ~/.env.example ~/.env
echo "VAR=value" >> ~/.env
```

### 6. Languages and dependencies

#### Node.js

Install the saved [Node.js](https://nodejs.org) with [nodenv](https://github.com/nodenv/nodenv) and use the custom [`dependencies` plugin](/.zsh/plugins/dependencies/dependencies.plugin.zsh) to install global packages:

```sh
for version in $(command ls ~/.npm/global); do
  nodenv install $version --skip-existing
  cd ~/.npm/global/$version
  npm -g install $(dependencies -L)
done
```

Link the global Node.js version to the current one:

```sh
nodenv global $(cat ~/.node-version)
rm -f $NODENV_ROOT/version && ln -sf ~/.node-version $NODENV_ROOT/version
```

#### Ruby

Install and link the [Ruby](https://www.ruby-lang.org) version in use with [rbenv](https://github.com/rbenv/rbenv):

```sh
rbenv install $(cat ~/.ruby-version) --skip-existing
rbenv global $(cat ~/.ruby-version)
rm -f $RBENV_ROOT/version && ln -sf ~/.ruby-version $RBENV_ROOT/version
```

#### Python

Install and link the [Python](https://www.python.org) version in use with [pyenv](https://github.com/pyenv/pyenv):

```sh
pyenv install $(cat ~/.python-version) --skip-existing
pyenv global $(cat ~/.python-version)
rm -f $PYENV_ROOT/version && ln -sf ~/.python-version $PYENV_ROOT/version
```

### 7. [VSCode](https://code.visualstudio.com)

#### Settings, snippets and extensions

Use symlinks to backup keybindings, settings, snippets and extensions.

> [!WARNING]
> The following operations will permanently replace some system folders with symlinks.

```sh
for config in keybindings.json settings.json snippets; do
  file=~/Library/Application\ Support/Code/User/$config
  rm -rf $file
  ln -sf ~/.vscode/user/$config $file
done

rm -rf ~/.vscode/extensions/extensions.json
ln -sf ~/.vscode/user/extensions.json ~/.vscode/extensions/extensions.json
```

#### Keybindings

To avoid emitting beeps with the keyboard combinations `^⌘←`, `^⌘↓` and `^⌘`, create the following configuration file:

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

For more information see [this GitHub issue](https://github.com/electron/electron/issues/2617#issuecomment-571447707).

### 8. Resources

#### Fonts
    
To display icons in your terminal, download a font supporting Nerd Fonts, like [Monaco](https://github.com/Karmenzind/monaco-nerd-fonts/tree/master/fonts), and use it in apps supporting command line interfaces (Terminal, iTerm, VSCode, etc).

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
  # Create the folder in iCloud Drive if it doesn't exist.
  cloud_folder=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
  [[ ! -d $cloud_folder ]] && mkdir $cloud_folder

  case $folder in
    # Replace with a symlink to the system folder.
    Applications)
      rm -rf ~/Applications 
      ln -sf /Applications ~/Applications
      ln -sf $cloud_folder /Applications/iCloud
      ;;
    # Create a symlink named `iCloud`.
    Developer|Pictures)
      ln -sf $cloud_folder ~/$folder/iCloud
      ;;
    # Replace with a symlink to the cloud folder.
    Downloads|Movies|Music)
      [[ -d ~/$folder ]] && mv ~/$folder/* $cloud_folder 2>/dev/null
      rm -rf ~/$folder && ln -sf $cloud_folder ~/$folder
      ;;
  esac
done
```

The new folder icons can be replaced manually. System icons can be found here:

```sh
open /System/Library/Extensions/IOStorageFamily.kext/Contents/Resources
```

You can easily link applications stored in the cloud to the system folder:

```sh
ln -sf ~/Applications/Bartender.app /Applications/Bartender.app
``` 

The app will become available in the menu and maintain all system-wide functionalities, including automatic updates.
