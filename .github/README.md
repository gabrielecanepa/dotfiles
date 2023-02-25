## Installation

1. To display icons in your terminal, download a font like [Monaco Nerd Mono](https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.ttf?raw=true), then install it in your system and make it the default font in all apps using terminal interfaces (Terminal, iTerm, VSCode, etc).

2. Clone the repository and move all files to your `$HOME`:

  ```sh
  git clone git@github.com:gabrielecanepa/dotfiles.git
  # Move manually or move all (WARN: this will overwrite the existing files)
  mv -vf dotfiles/* ~/ && rm -rf dotfiles && cd ~
  ```

3. Create .zprofile and add private information:

  ```sh
  touch ~/.zprofile

  # Add the following variables
  export NAME="..."
  export EMAIL="..."
  export WORKING_DIR="..."
  ```

4. Install Oh My Zsh and some essential plugins:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
  # Plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  ```

1. Install Homebrew and the bundled packages:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew bundle --file ~/.Brewfile
  ```

6. Install the latest versions of Node.js ([fnm](https://github.com/Schniz/fnm)), Ruby ([rbenv](https://github.com/rbenv/rbenv)) and Python ([pyenv](https://github.com/pyenv/pyenv)):

  ```sh
  # Make sure that all packages are up-to-date.
  brew update && brew upgrade

  # fnm
  fnm install --lts && fnm use lts-latest
  # rbenv
  rbenv install $(rbenv-latest) && rbenv global $(rbenv-latest)
  # pyenv
  pyenv install $(pyenv-latest) && pyenv global $(pyenv-latest)
  ```

7. Install global Yarn packages:

  ```sh
  # Set up global folder
  [[ ! -d ~/.config/yarn/global ]] && mkdir -p ~/.config/yarn/global
  # Link to ~/.yarn
  ln -sf ~/.yarn ~/.config/yarn/global
  # Install packages
  yarn global add
  ```

8. Sync local folders with iCloud:

  ```sh
  for folder in (Applications Downloads Movies Music Pictures); do
    icloud_folder=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
    [[ ! -d $icloud_folder ]] && mkdir $icloud_folder

    case $folder in
      Applications|Downloads|Movies|Music) # replace with symlink to iCloud
        [[ -d ~/$folder ]] && mv ~/$folder/* $icloud_folder
        rm -rf ~/$folder && ln -sf $icloud_folder ~/$folder
        ;;
      Pictures) # can't be modified, add a symlink to iCloud
        ln -sf $icloud_folder ~/Pictures/iCloud\ Pictures
        ;;
    esac
  done
  unset folder icloud_folder
  ```
