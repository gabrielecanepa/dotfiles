## Installation

> **Warning**  
> If you want to try the following dotfiles, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. 
> Use at your own risk!

### Fonts
    
To display icons in your terminal, download a font supporting [Nerd Fonts](https://nerdfonts.com), like [Monaco Nerd Mono](https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.ttf?raw=true). Then install it in your system and use it in apps using terminal interfaces (Terminal, iTerm, VSCode, etc).

### Dotfiles

Clone [this repository](https://github.com/gabrielecanepa/dotfiles):

```sh
git clone git@github.com:gabrielecanepa/dotfiles.git
# or
gh repo clone gabrielecanepa/dotfiles
```

Then move all files to your home directory, manually or in bulk.

> **Warning**  
> The following command will overwrite all existing files in your home directory, make sure to backup your data before proceeding.

```sh
mv -vf dotfiles/* ~/ && cd ~
```

### Profile

Create a `.profile` file in your home directory

```sh
touch ~/.profile
```

and use it to export the following variables:

```sh
export NAME="..."
export EMAIL="..."
export WORKING_DIR="..."
```

### [Oh My Zsh](https://ohmyz.sh)

Install Oh My Zsh with [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions), [`zsh-completions`](https://github.com/zsh-users/zsh-completions) and [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting):

```sh
/bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"

for plugin in zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
  git clone https://github.com/zsh-users/${plugin}.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${plugin}
done
```

### [Homebrew](https://brew.sh)

Install Homebrew and the packages bundled in [`.Brewfile`](https://github.com/gabrielecanepa/dotfiles/blob/dotfiles/.Brewfile):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file ~/.Brewfile
```

### [Node.js](https://nodejs.org), [Ruby](https://ruby-lang.org) and [Python](https://python.org)

Install the latest stable version of Node.js ([nodenv](https://github.com/nodenv/nodenv)), Ruby ([rbenv](https://github.com/rbenv/rbenv)) and Python ([pyenv](https://github.com/pyenv/pyenv)) using the custom [`lts` plugin](https://github.com/gabrielecanepa/dotfiles/blob/dotfiles/.zsh/plugins/lts/lts.plugin.zsh):

```sh
# Make sure that all packages are up-to-date.
brew update && brew upgrade
# Install the latest stable version of node, ruby and python.
lts install
```

### [npm](https://npmjs.com)

First, install the Node.js versions specified in [`.npm/versions`](/.npm/versions). For each version, use the [`dependencies` plugin](/.zsh/plugins/dependencies/dependencies.plugin.zsh) to install its global packages:

```sh
for version in $(command ls ~/.npm/versions); do
  nodenv install $version --skip-existing
  cd ~/.npm/versions/$version
  npm -g install $(dependencies -L)
done
```

### [pnpm](https://pnpm.js.org)

Install pnpm and its global packages:

```sh
npm install -g pnpm
pnpm install -g
```

### [Yarn](https://classic.yarnpkg.com)

Set up and install global Yarn packages with:

```sh
# Set up a global folder.
[[ ! -d ~/.config/yarn ]] && mkdir -p ~/.config/yarn
ln -sf ~/.yarn ~/.config/yarn/global

# Install the packages specified in ~/.yarn
yarn global add
```

#### [Yarn PnP](https://yarnpkg.com)

Install Yarn Pnp using [Corepack](https://nodejs.org/api/corepack):

```sh
corepack enable
corepack prepare yarn@stable --activate
```

When using the custom [`yarn1` plugin](/.zsh/plugins/yarn1/yarn1.plugin.zsh), the classic version will be available with `yarn`, while the new version can be activated with either `yarn2`, `yarnpnp` or `berry`.

### [iCloud](https://icloud.com)

#### Folders

> **Warning**  
> The following operations will permanently replace some system folders with symbolic links to iCloud Drive.

The snippet will:
- Replace the user Downloads, Movies and Music folders with a symbolic link to the corresponding (new or existing) folder in `~/Library/Mobile Documents/com~apple~CloudDocs`. This grants continuous synchronization using iCloud.
- Replace the user Applications folder with a symlink to the system Applications folder.
- Create a symlink named `iCloud` in `/Applications`, `~/Developer` and `~/Pictures` directing to the related cloud folders.

<br>

```sh
for folder in Applications Developer Downloads Movies Music Pictures; do
  # Create the folder in iCloud Drive if it doesn't exist.
  cloud_path=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
  [[ ! -d $cloud_path ]] && mkdir $cloud_path

  case $folder in
    # Replace with a symlink to the system folder.
    Applications)
      rm -rf ~/Applications 
      ln -sf /Applications ~/Applications
      ln -sf $cloud_path /Applications/iCloud
      ;;
    # Create a symlink named `iCloud`.
    Developer|Pictures)
      ln -sf $cloud_path ~/$folder/iCloud
      ;;
    # Replace with a symlink to the cloud folder.
    Downloads|Movies|Music)
      [[ -d ~/$folder ]] && mv ~/$folder/* $cloud_path 2>/dev/null
      rm -rf ~/$folder && ln -sf $cloud_path ~/$folder
      ;;
  esac
done
```

#### Applications

You can easily link single applications stored in the cloud with:

```sh
ln -sf ~/Applications/<APP_NAME>.app /Applications/<APP_NAME>.app
``` 

Applications stored in the cloud can maintain all system-wide functionalities and update automatically.

### [VSCode](https://code.visualstudio.com)

#### Settings, snippets and extensions

> **Warning**  
> The following operations will permanently replace some system folders with symlinks.

Set `VSCODE_CUSTOM` in [`.zshrc`](/.zshrc) and use symlinks to backup keybindings, settings, snippets and extensions:

```sh
for _type in keybindings.json settings.json snippets; do
  _path=~/Library/Application\ Support/Code/User/$_type
  rm -rf $_path
  ln -sf $VSCODE_CUSTOM/$_type $_path
done

rm -rf ~/.vscode/extensions/extensions.json
ln -sf $VSCODE_CUSTOM/extensions.json ~/.vscode/extensions/extensions.json
```

#### Keybindings

To avoid triggering beeps with the keyboard combinations `^⌘←`, `^⌘↓` and `^⌘`, create the file `~/Library/KeyBindings/DefaultKeyBinding.dict` with the following content:

```
{
  "^@\UF701" = "noop";
  "^@\UF702" = "noop";
  "^@\UF703" = "noop";
}
```

For more information see [this issue](https://github.com/electron/electron/issues/2617#issuecomment-571447707).
