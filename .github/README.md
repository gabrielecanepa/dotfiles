## Installation

1. Clone the repository and move all files to `$HOME`

   ```sh
   git clone git@github.com:gabrielecanepa/dotfiles.git
   mv -vf dotfiles/* ~/
   rm -rf dotfiles
   cd ~
   ```
 
2. Install Homebrew and global packages

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew bundle install --global
   ```

3. Install `nvm` and latest Node version

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh)"
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
   nvm install node
   ```

4. Install Oh My Zsh and essential plugins

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
   # Plugins
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
   ```
   
5. To display icons in your terminal, download a font like [Monaco Nerd Mono](https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.otf?raw=true), then install it in your system and make it the default font in all apps using a terminal interface (Terminal, iTerm, VSCode, etc.)

6. Reload Zsh

   ```sh
   omz reload
   ```
   
7. Install global Yarn packages

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
   
8. Install the latest Ruby version

   ```sh
   rbenv install $(rbenv install -l | grep -v - | tail -1)
   ```

TODO:
- [ ] List all tools and their usage
- [ ] Add installation file and quickstart guide
- [ ] Add Python installation instructions
- [ ] Review steps order and write step-by-step instructions
