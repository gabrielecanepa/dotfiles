## Installation

1. To display icons in your terminal, download a font like [Monaco Nerd Mono](https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.ttf?raw=true), then install it in your system and make it the default font in all apps using a terminal interface (Terminal, iTerm, VSCode, etc.)

2. Clone the repository and move all files to your `$HOME`

   ```sh
   git clone git@github.com:gabrielecanepa/dotfiles.git
   mv -vf dotfiles/* ~/
   rm -rf dotfiles
   cd ~
   ```

3. Install Oh My Zsh and some essential plugins

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
  # Plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  ```

4. Install Homebrew and global packages

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew bundle install --global
   ```

5. Install global Yarn packages

   ```sh
   # Set up config folder
   if [ -d ~/.config ]; then
     [ ! -d ~/.config/yarn ] && mkdir ~/.config/yarn
     rm -rf ~/.config/yarn/global
   else
     mkdir ~/.config && mkdir ~/.config/yarn
   fi
   # Link to existing ~/.yarn folder
   ln -sf ~/.yarn ~/.config/yarn/global
   # Install packages
   yarn global install
   ```

6. Install the latest versions

   ```sh
   rbenv install $(rbenv install -l | grep -v - | tail -1)
   ```
