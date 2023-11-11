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

### Oh My Zsh

Install [Oh My Zsh](https://ohmyz.sh) with [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions), [`zsh-completions`](https://github.com/zsh-users/zsh-completions) and [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting):

```sh
/bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"

for plugin in zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
  git clone https://github.com/zsh-users/${plugin}.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${plugin}
done
```

### Homebrew

Install [Homebrew](https://brew.sh) and the packages bundled in [`.Brewfile`](https://github.com/gabrielecanepa/dotfiles/blob/dotfiles/.Brewfile):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file ~/.Brewfile
```

### Node.js, Ruby and Python

Install the latest stable version of Node.js ([nodenv](https://github.com/nodenv/nodenv)), Ruby ([rbenv](https://github.com/rbenv/rbenv)) and Python ([pyenv](https://github.com/pyenv/pyenv)) using the custom [lts plugin](https://github.com/gabrielecanepa/dotfiles/blob/dotfiles/.zsh/plugins/lts/lts.plugin.zsh):

```sh
# Make sure that all packages are up-to-date.
brew update && brew upgrade

# Install the latest stable version of node, ruby and python.
lts install
```

### Yarn

Set up and install global [Yarn](https://classic.yarnpkg.com) packages with:

```sh
# Set up a global folder.
[[ ! -d ~/.config/yarn ]] && mkdir -p ~/.config/yarn
ln -sf ~/.yarn ~/.config/yarn/global

# Install the packages specified in ~/.yarn
yarn global add
```

#### Yarn Pnp

Install [Yarn Pnp](https://yarnpkg.com/features/pnp) using Node.js's [Corepack](https://nodejs.org/api/corepack):

```sh
corepack enable
corepack prepare yarn@stable --activate
```

When using the custom [yarnx plugin](../.zsh/plugins/yarnx/yarnx.plugin.zsh) plugin, the classic version will be available under `yarn`, while the new version can be activated with either `yarn2`, `yarnpnp` or `berry`.

### iCloud

#### Cloud folders

> **Warning**  
> The following operations will permanently replace some system folders with symbolic links to iCloud Drive.

The snippet will:
- Replace the user Downloads, Movies and Music folders with a symbolic link to the corresponding (new or existing) folder in `~/Library/Mobile Documents/com~apple~CloudDocs`. This grants continuous synchronization using iCloud.
- Replace the user Applications folder with a symlink to the system Applications folder.
- Create a symlink named `iCloud` in `/Applications`, `~/Developer` and `~/Pictures` directing to the related cloud folders.

<br>

```sh
for folder in Applications Developer Downloads Movies Music Pictures; do
  cloud_path=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
  [[ ! -d $cloud_path ]] && mkdir $cloud_path

  case $folder in
    Applications)
      rm -rf ~/Applications 
      ln -sf /Applications ~/Applications
      ln -sf $cloud_path /Applications/iCloud
      ;;
    Developer|Pictures)
      ln -sf $cloud_path ~/$folder/iCloud
      ;;
    Downloads|Movies|Music)
      [[ -d ~/$folder ]] && mv ~/$folder/* $cloud_path 2>/dev/null
      rm -rf ~/$folder && ln -sf $cloud_path ~/$folder
      ;;
  esac
done
```

#### Cloud applications

You can easily link single applications stored in the cloud with:

```sh
ln -sf ~/Applications/<APP_NAME>.app /Applications/<APP_NAME>.app
``` 

Applications stored in the cloud can maintain all system-wide functionalities and update automatically.

### VSCode

#### Settings, snippets and extensions

> **Warning**  
> The following operations will permanently replace some system folders with symlinks.

Use symlinks to backup VSCode keybindings, settings, snippets and extensions to `~/.vscode/user`:

```sh
for file in keybindings.json settings.json snippets; do
  path=~/Library/Application\ Support/Code/User/$file
  rm -rf $path
  ln -sf ~/.vscode/user/$file $path
done

rm -rf ~/.vscode/extensions/extensions.json
ln -sf ~/.vscode/user/extensions.json ~/.vscode/extensions/extensions.json
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
