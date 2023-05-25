## Installation

1. To display icons in your terminal, download a font like [Monaco Nerd Mono](https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.ttf?raw=true), then install it in your system and make it the default font in all apps using terminal interfaces (Terminal, iTerm, VSCode, etc).

2. Clone the repository and move all files to your `$HOME`:

    ```sh
    git clone git@github.com:gabrielecanepa/dotfiles.git
    # Move manually or move all (WARN: the following command will overwrite any existing file)
    mv -vf dotfiles/* ~/ && rm -rf dotfiles && cd ~
    ```

3. Create a `.profile` file and export the required variables:

    ```sh
    touch ~/.profile
    ```

    In `.profile`:

    ```sh
    export NAME="..."
    export EMAIL="..."
    export WORKING_DIR="..."
    ```

4. Install Oh My Zsh and some essential plugins:

    ```sh
    /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"

    for plugin in zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
      git clone https://github.com/zsh-users/${plugin}.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${plugin}
    done
    ```

5. Install Homebrew and the bundled packages:

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
    for folder in (Applications Developer Downloads Movies Music Pictures); do
      icloud_folder=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
      [[ ! -d $icloud_folder ]] && mkdir $icloud_folder

      case $folder in
        # Add symlink to icloud
        Applications)
          ln -sf $icloud_folder /Applications/iCloud\ Applications
          ;;
        Developer|Pictures)
          ln -sf $icloud_folder ~/$folder/iCloud\ $folder
          ;;
        # Replace with symlink to icloud
        Downloads|Movies|Music)
          mv ~/$folder/* $icloud_folder
          sudo rm -rf ~/$folder && ln -sf $icloud_folder ~/$folder
          ;;
      esac
    done
    ```

9. Sync Mac preferences using iCloud

    ```sh
    icloud_system=~/Library/Mobile\ Documents/com~apple~CloudDocs/System/Preferences
    icloud_preferences=$icloud/System/Preferences

    [[ ! -d $icloud_system ]] && mkdir $icloud_system
    [[ ! -d $icloud_preferences ]] && sudo cp -r ~/Library/Preferences $icloud_preferences
    sudo rm -rf ~/Library/Preferences && ln -sf $icloud_preferences ~/Library/Preferences
    ```
