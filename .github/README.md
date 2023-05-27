## Installation

1. **Fonts**
    
   To display icons in your terminal, download a font supporting [Nerd Fonts](https://nerdfonts.com), like [Monaco Nerd Mono](https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.ttf?raw=true). Then, install it in your system and make it default in apps using terminal interfaces (Terminal, iTerm, VSCode, etc).

2. **Dotfiles**

    Clone [the repository](https://github.com/gabrielecanepa/dotfiles)

    ```sh
    git clone git@github.com:gabrielecanepa/dotfiles.git
    ```
    
    then move all files to your `$HOME` directory, manually or all together:

    > **Warning**  
    > The following command will overwrite any existing files
    
    ```sh
    mv -vf dotfiles/* ~/ && cd ~
    ```

3. **Profile** 

    Create a `.profile` file

    ```sh
    touch ~/.profile
    ```

    and use it to export the following variables:

    ```sh
    export NAME="..."
    export EMAIL="..."
    export WORKING_DIR="..."
    ```

4. **Oh My Zsh**

    Install [Oh My Zsh](https://ohmyz.sh) with [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [zsh-completions](https://github.com/zsh-users/zsh-completions) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting):

    ```sh
    /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
    ```
    
    ```sh
    zsh_plugins=(zsh-autosuggestions zsh-completions zsh-syntax-highlighting)

    for plugin in $zsh_plugins; do
      git clone https://github.com/zsh-users/${plugin}.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${plugin}
    done
    ```
    
    > **Note**: reload with `omz reload` or `zsh` to apply the new configuration

5. **Homebrew**

    Install [Homebrew](https://brew.sh)

    ```sh
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
    
    and the bundled packages:
    
    ```sh
    brew bundle --file ~/.Brewfile
    ```
    > **Note**: reload with `omz reload` or `zsh` to apply the new configuration

6. **Node.js**, **Ruby** and **Python**

    Install the latest versions of [Node.js](https://nodejs.org) with [fnm](https://github.com/Schniz/fnm), [Ruby](https://ruby-lang.org) with [rbenv](https://github.com/rbenv/rbenv) and [Python](https://python.org) with [pyenv](https://github.com/pyenv/pyenv):

    ```sh
    # Make sure that all packages are up-to-date.
    brew update && brew upgrade

    fnm install --lts && fnm use lts-latest
    rbenv install $(rbenv-latest) && rbenv global $(rbenv-latest)
    pyenv install $(pyenv-latest) && pyenv global $(pyenv-latest)
    ```
    > **Note**: reload with `omz reload` or `zsh` to apply the new configuration

7. **Yarn**

    Set up and install global [Yarn](https://yarnpkg.com) packages with:
    
    > **Warning**  
    > All existing packages will be moved to `~/.config/yarn/global.backup`

    ```sh
    # Set up global folder and link to ~/.yarn
    [[ -d ~/.config/yarn/global ]] && cp -r ~/.config/yarn/global ~/.config/yarn/global.backup && rm -rf ~/.config/yarn/global
    [[ ! -d ~/.config/yarn ]] && mkdir -p ~/.config/yarn
    ln -sf ~/.yarn ~/.config/yarn/global

    # Install packages
    yarn global add
    ```

8. **iCloud**

    > **Warning**  
    > This operation will permanently replace some system folders with symbolic links to iCloud
    
    Sync local folders with iCloud:

    ```sh
    for folder in Applications Developer Downloads Movies Music Pictures; do
      icloud_folder=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
      [[ ! -d $icloud_folder ]] && mkdir $icloud_folder

      case $folder in
        # Add symlink to icloud
        Developer)
          ln -sf $icloud_folder ~/$folder/icloud
          ;;
        Pictures)
          ln -sf $icloud_folder ~/$folder/iCloud
          ;;
        # Replace with symlink to icloud
        Applications|Downloads|Movies|Music)
          mv ~/$folder/* $icloud_folder 2>/dev/null
          sudo rm -rf ~/$folder && ln -sf $icloud_folder ~/$folder
          ;;
      esac
    done
    ```
