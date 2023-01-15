## Installation

1. To display icons in your terminal, download a font like [Monaco Nerd Mono](https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.ttf?raw=true), then install it in your system and make it the default font in all apps using a terminal interface (Terminal, iTerm, VSCode, etc.).

2. Clone the repository and move all files to your `$HOME`:

  ```sh
  git clone git@github.com:gabrielecanepa/dotfiles.git
  # Move manually or move all:
  mv -vf dotfiles/* ~/
  rm -rf dotfiles
  cd ~
  ```

3. Install Oh My Zsh and some essential plugins:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
  # Plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  ```

4. Install Homebrew and the bundled global packages:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew bundle --file ~/.Brewfile
  ```

5. Install the latest Node.js ([fnm](https://github.com/Schniz/fnm)) and Ruby ([rbenv](https://github.com/rbenv/rbenv)) versions:

  ```sh
  fnm install --lts
  rbenv install "$(rbenv install -l | grep  -v - | tail -1)"
  ```

6. Install global Yarn packages:

  ```sh
  # Set up config folder
  if [[ -d ~/.config ]]; then
    [[ ! -d ~/.config/yarn ]] && mkdir ~/.config/yarn
    rm -rf ~/.config/yarn/global
  else
    mkdir ~/.config && mkdir ~/.config/yarn
  fi
  # Link to existing ~/.yarn folder
  ln -sf ~/.yarn ~/.config/yarn/global
  # Install packages
  yarn global add
  ```

1. Sync local folders with iCloud:

  ```sh
  for folder in (Applications Downloads Movies Music Pictures); do
    icloud_folder=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
    [[ ! -d $icloud_folder ]] && mkdir $icloud_folder

    case $folder in
      Applications) # create symlink to local Applications folder
        [[ -d ~/Applications ]] && mv ~/Applications/* $icloud_folder
        rm -rf ~/Applications && ln -sf /Applications ~/Applications
        ;;
      Downloads|Movies|Music) # replace with symlink to iCloud
        [[ -d ~/$folder ]] && mv ~/$folder/* $icloud_folder
        rm -rf ~/$folder && ln -sf $icloud_folder ~/$folder
        ;;
      Pictures) # can't be modified - create a symlink to iCloud
        [[ ! -L ~/Pictures/Pictures ]] && ln -sf $icloud_folder ~/Pictures/Pictures
        ;;
    esac
  done

  unset folder icloud_folder
  ```
