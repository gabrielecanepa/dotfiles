## Installation

1. Clone the repository and copy the files to `$HOME`
   ```sh
   git clone git@github.com:gabrielecanepa/dotfiles.git
   cp -af gabrielecanepa/dotfiles/. ~
   ```
2. Install Homebrew and download packages
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   # Global packages
   brew bundle install --global
   ```
3. Install `nvm`
   ```sh
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
   ```
4. Install Oh My Zsh with plugins
   ```sh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   # Plugins
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
   ```
5. Install Monaco Nerd font from https://github.com/Karmenzind/monaco-nerd-fonts
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
8. Install latest Node version
   ```sh
   nvm install node
   ```
9. Install latest Ruby version
   ```
   rbenv install --list
   rbenv install <version>
   ```

TODO:
[ ] Review steps order
[ ] Add installation file
[x] Add Yarn global instructions
