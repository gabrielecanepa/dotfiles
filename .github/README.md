## Installation

> **Warning:** 
> If you want to try the following dotfiles, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

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
    
    for plugin in zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
      git clone https://github.com/zsh-users/${plugin}.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${plugin}
    done
    ```

5. **Homebrew**

    Install [Homebrew](https://brew.sh) and the bundled packages:

    ```sh
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    brew bundle --file ~/.Brewfile
    ```

6. **Node.js**, **Ruby** and **Python**

    Install the latest stable version of [Node.js](https://nodejs.org) ([`nodenv`](https://github.com/nodenv/nodenv)), [Ruby](https://ruby-lang.org) ([`rbenv`](https://github.com/rbenv/rbenv)) and [Python](https://python.org) ([`pyenv`](https://github.com/pyenv/pyenv)) using the custom [`lts` plugin](../.zsh/plugins/lts/lts.plugin.zsh):

    ```sh
    # Make sure that all packages are up-to-date.
    brew update && brew upgrade

    lts install node ruby python
    ```

7. **Yarn**

    Set up and install global [Yarn](https://classic.yarnpkg.com) packages with:

    ```sh
    [[ ! -d ~/.config/yarn ]] && mkdir -p ~/.config/yarn
    ln -sf ~/.yarn ~/.config/yarn/global
    yarn global add
    ```

    Install [Yarn Pnp](https://yarnpkg.com/features/pnp) using Node.js's [Corepack](https://nodejs.org/api/corepack):

    ```sh
    corepack enable
    corepack prepare yarn@stable --activate
    ```

    When using the custom [`yarnx` plugin](../.zsh/plugins/yarnx/yarnx.plugin.zsh) plugin, the classic version will be available under `yarn`, while the new version can be activated with either `yarn2`, `yarnpnp` or `berry`.

8. **iCloud**

    > **Warning**  
    > The following operations will permanently replace some system folders with symbolic links to iCloud Drive.
    >
    > The snippet will:
    > - Replace the Applications, Downloads, Movies and Music folders with a symbolic link to the corresponding (new or existing) folder in `~/Library/Mobile Documents/com~apple~CloudDocs`. This grants continuous synchronization using iCloud.
    > - Create a symlink named `icloud` in the Developer folder pointing to the corresponding cloud folder. Synchronization is not needed as everything in the local Developer folder should be tracked with Git, but a remote folder can be used to store additional assets and resources.
    > - Create a symlink named `iCloud` in Pictures pointing to the same cloud folder. The local Pictures folder has an ACL preventing user deletion and can't be replaced.
 
    <br>

    ```sh
    for folder in Applications Developer Downloads Movies Music Pictures; do
      cloud_folder=~/Library/Mobile\ Documents/com~apple~CloudDocs/$folder
      [[ ! -d $cloud_folder ]] && mkdir $cloud_folder

      case $folder in
        # Replace with a symlink to iCloud.
        Applications|Downloads|Movies|Music)
          mv ~/$folder/* $cloud_folder 2>/dev/null
          sudo rm -rf ~/$folder && ln -sf $cloud_folder ~/$folder
          ;;
        # Create a symlink to iCloud.
        Developer)
          ln -sf $cloud_folder ~/Developer/icloud
          ;;
        Pictures)
          ln -sf $cloud_folder ~/Pictures/iCloud
          ;;
      esac
    done
    ```

    You can link single applications stored in the iCloud `Applications` folder with: 
    
    ```sh
    ln -sf ~/Applications/<APP_NAME>.app /Applications/<APP_NAME>.app
    ``` 
    
    Or alternatevely create an alias manually and move it to `/Applications`.
    
    The applications stored in the cloud will maintain all system-wide functionalities and update automatically.

9. **VSCode**

    > **Warning**  
    > The following operations will permanently replace some system folders with symlinks to `~/.vscode/user`.

    Use symlinks to backup VSCode settings and extensions for both stable and insiders versions:

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

10. **MacOS**

    Apply the system settings specified in [`.macos`](../.macos):

    ```sh
    . ~/.macos
    ```
