## Installation

1. **Font**
    
   To display icons in your terminal, download a font supporting [Nerd Fonts](https://nerdfonts.com), like [Monaco Nerd Mono](https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.ttf?raw=true). Then install it in your system and use it in apps using terminal interfaces (Terminal, iTerm, VSCode, etc).

2. **Dotfiles**

    Clone [the repository](https://github.com/gabrielecanepa/dotfiles)

    ```sh
    git clone git@github.com:gabrielecanepa/dotfiles.git
    ```
    
    then move all files to your `$HOME` directory, manually or in bulk:

    > **Warning**  
    > The following command will overwrite all existing files.
    
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

5. **Homebrew**

    Install [Homebrew](https://brew.sh)

    ```sh
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
    
    and the bundled packages:
    
    ```sh
    brew bundle --file ~/.Brewfile
    ```

6. **Node.js**, **Ruby** and **Python**

    Install the latest versions of [Node.js](https://nodejs.org) with [fnm](https://github.com/Schniz/fnm), [Ruby](https://ruby-lang.org) with [rbenv](https://github.com/rbenv/rbenv) and [Python](https://python.org) with [pyenv](https://github.com/pyenv/pyenv):

    ```sh
    # Make sure that all packages are up-to-date.
    brew update && brew upgrade

    fnm install --lts && fnm use lts-latest
    rbenv install $(rbenv-latest) && rbenv global $(rbenv-latest)
    pyenv install $(pyenv-latest) && pyenv global $(pyenv-latest)
    ```

7. **Yarn**

    Set up and install global [Yarn](https://classic.yarnpkg.com) packages with:
    
    > **Note**  
    > Any existing packages will be moved to `~/.config/yarn/global.backup`.

    ```sh
    # Set up global folder and link to ~/.yarn
    [[ -d ~/.config/yarn/global ]] && cp -r ~/.config/yarn/global ~/.config/yarn/global.backup && rm -rf ~/.config/yarn/global
    [[ ! -d ~/.config/yarn ]] && mkdir -p ~/.config/yarn
    ln -sf ~/.yarn ~/.config/yarn/global

    # Install packages
    yarn global add
    ```

    Install [Yarn Berry](https://yarnpkg.com) using [Corepack](https://nodejs.org/api/corepack):

    ```sh
    corepack enable # if not already enabled
    corepack prepare yarn@stable --activate
    ```

    Thanks to the [berry plugin](../.zsh/plugins/berry/berry.plugin.zsh), the classic version will be available with the standard `yarn` command, while the new version can be used with `berry`.

8. **iCloud**

    > **Warning**  
    > The following operations will permanently replace some system folders with symbolic links to iCloud Drive.
    
    The following script will:
    - Replace the Applications, Downloads, Movies and Music folders with a symbolic link to the corresponding (new or existing) folder in `~/Library/Mobile Documents/com~apple~CloudDocs`. This grants continuous synchronization using iCloud.
    - Create a symlink named `icloud` in the Developer folder pointing to the corresponding cloud folder. Synchronization is not needed as everything in the local Developer folder should be tracked with Git, but a cloud folder can be useful to store additional assets and resources.
    - Create a symlink named `iCloud` in Pictures pointing to the same cloud folder. The local Pictures folder has an ACL preventing user deletion and can't be replaced.
 
    <br>

    ```sh
    for folder in Applications Developer Downloads Movies Music Pictures; do
      icloud_folder=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
      [[ ! -d $icloud_folder ]] && mkdir $icloud_folder

      case $folder in
        # Replace with symlink to icloud
        Applications|Downloads|Movies|Music)
          mv ~/$folder/* $icloud_folder 2>/dev/null
          sudo rm -rf ~/$folder && ln -sf $icloud_folder ~/$folder
          ;;
        # Add symlink to icloud
        Developer)
          ln -sf $icloud_folder ~/Developer/icloud
          ;;
        Pictures)
          ln -sf $icloud_folder ~/Pictures/iCloud
          ;;
      esac
    done
    ```

    > **Note**  
    > You can link applications stored in the cloud with `ln -sf ~/Applications/<APP_NAME>.app /Applications/<APP_NAME>.app` or create an alias and move it to `/Applications`.
    > The applications will become available in the system and update when the version changes.

9. **VSCode**

    > **Warning**  
    > The following operations will permanently replace some system folders with symlinks to `~/.vscode/user`.

    Create symlinks to backup VSCode settings and extensions, working with both the stable and insiders versions:

    ```sh
    # Settings
    code=~/Library/Application\ Support/Code/User
    code_insiders=~/Library/Application\ Support/Code\ -\ Insiders/User

    for file in keybindings.json settings.json snippets; do
      rm -rf $code/$file $code_insiders/$file
      ln -sf ~/.vscode/user/$file $code/$file
      ln -sf ~/.vscode/user/$file $code_insiders/$file
    done
    
    # Extensions
    rm -rf ~/.vscode/extensions/extensions.json
    ln -sf ~/.vscode/user/extensions.json ~/.vscode/extensions/extensions.json
    ```
