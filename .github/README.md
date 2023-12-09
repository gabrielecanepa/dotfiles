
## Installation
> **Warning**  
> If you want to try the following dotfiles, you should first fork this repository, review the code and remove things you don’t want or need. **Don’t blindly use my settings** unless you know what that entails!

### Fonts
    
To display icons in your terminal, download a font supporting Nerd Fonts, like [Monaco](https://github.com/Karmenzind/monaco-nerd-fonts), and use it in apps supporting command line interfaces (Terminal, iTerm, VSCode, etc).

### Dotfiles

Clone this repository:

```sh
git clone git@github.com:gabrielecanepa/dotfiles.git
# or
gh repo clone gabrielecanepa/dotfiles
```

And move all files to your home directory, manually or in bulk.

> **Warning**  
> The following command will overwrite all existing files in your home directory, make sure to backup your data before proceeding.

```sh
mv -vf dotfiles/* ~ && cd ~
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

### SSH

Generate a new SSH key and copy it to the clipboard:

```sh
ssh-keygen -t ed25519 -C "<comment>"
tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
```

Add the public key to [GitHub](https://github.com/settings/ssh/new) and [GitLab](https://gitlab.com/-/profile/keys).

### [Oh My Zsh](https://ohmyz.sh)

Install Oh My Zsh with plugins from [zsh-users](https://github.com/zsh-users):

```sh
/bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"

for plugin in zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
  git clone https://github.com/zsh-users/${plugin}.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${plugin}
done; unset plugin
```

### [Homebrew](https://brew.sh)

Install Homebrew and all packages specified in the [`Brewfile`](/.Brewfile):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file ~/.Brewfile
```

### [Node.js](https://nodejs.org), [Ruby](https://ruby-lang.org) and [Python](https://python.org)

Install the latest stable version of Node.js, Ruby and Python using the custom [`lts` plugin](/.zsh/plugins/lts/lts.plugin.zsh):

```sh
# Make sure that all packages are up-to-date.
brew update && brew upgrade
# Install the latest stable version of node, ruby and python.
lts install
```

### [npm](https://npmjs.com)

Install all versions in `.npm/global`. For each version, use the [`dependencies` plugin](/.zsh/plugins/dependencies/dependencies.plugin.zsh) to install the supported global packages:

```sh
for version in $(command ls ~/.npm/global); do
  nodenv install $version --skip-existing
  cd ~/.npm/global/$version
  npm -g install $(dependencies -L)
done; unset version
```

### [pnpm](https://pnpm.js.org)

Install pnpm and global packages:

```sh
npm install -g pnpm
pnpm install -g
```

### [Yarn](https://classic.yarnpkg.com)

Set up and install global Yarn packages:

```sh
# Set up a global folder.
[[ ! -d ~/.config/yarn ]] && mkdir -p ~/.config/yarn
ln -sf ~/.yarn ~/.config/yarn/global

# Install the packages specified in ~/.yarn
yarn global add
```

#### [Yarn PnP](https://yarnpkg.com)

Install Yarn Pnp using [Corepack](https://github.com/nodejs/corepack):

```sh
corepack enable
corepack prepare yarn@stable --activate
```

When using the custom [`yarn@1` plugin](/.zsh/plugins/yarn@1/yarn@1.plugin.zsh), the classic version will be available with `yarn`, while PnP can be activated with either `yarn2`, `yarnpnp` or `berry`.

### [iCloud](https://icloud.com)

#### Folders

Use this script to:
- Replace the home `Downloads`, `Movies` and `Music` folders with a symbolic link to the corresponding (new or existing) folder on iCloud. This grants continuous synchronization between the cloud and the local machine.
- Replace the home `Applications` folder with a symlink to the system applications folder, the one used by all users on the machine.
- Create a symlink named `iCloud`, pointing to the related cloud folder, in `Applications`, `Developer` and `Pictures`.

> **Warning**  
> The following operations will permanently replace some system folders with symbolic links to iCloud Drive.

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
done; unset cloud_folder folder
```

#### Applications

You can easily link applications stored in the cloud to the system folder:

```sh
for app in Bartender Dash iTerm2; do
  ln -sf ~/Applications/$app.app /Applications/$app.app
done; unset app
``` 

The apps will maintain all system-wide functionalities and update automatically.

### [VSCode](https://code.visualstudio.com)

#### Settings, snippets and extensions

Set `VSCODE_CUSTOM` in [`.zshrc`](/.zshrc) and use symlinks to backup keybindings, settings, snippets and extensions.

> **Warning**  
> The following operations will permanently replace some system folders with symlinks.

```sh
for config in keybindings.json settings.json snippets; do
  file=~/Library/Application\ Support/Code/User/$config
  rm -rf $file
  ln -sf $VSCODE_CUSTOM/$config $file
done; unset config file

rm -rf ~/.vscode/extensions/extensions.json
ln -sf $VSCODE_CUSTOM/extensions.json ~/.vscode/extensions/extensions.json
```

#### Keybindings

To avoid emitting beeps with the keyboard combinations `^⌘←`, `^⌘↓` and `^⌘`, create the configuration file:

```sh
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

For more information see [this Electron issue](https://github.com/electron/electron/issues/2617#issuecomment-571447707).
