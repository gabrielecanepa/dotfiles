# Get external or local IPs
alias ip="curl ipinfo.io/ip"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
alias speedtest="wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip"

# Serve the current directory as HTTP
alias serve="ruby -run -e httpd . -p 8000"

# git
alias ga="git add"
alias gbr="git branch"
alias gcm="git commit -m"
alias gco="git checkout"
alias glg="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gsts="git status -sb"
alias gpom="git push origin master"
alias gpf="git push -f --set-upstream $1 $2"

# Directories
alias code="cd $WORKING_DIR"
alias cdp="cd $WORKING_DIR/gabrielecanepa"
alias cdtr="cd $WORKING_DIR/trendiamo/core"
alias cdlw="cd $WORKING_DIR/lewagon"
alias tmp="cd $WORKING_DIR/tmp"

# Atom
alias atom="open -a Atom"
alias at="atom $1"
alias att="atom ."

# Files
alias aliases="open -a $TEXT_EDITOR $HOME/.aliases"
alias gitconfig="open -a $TEXT_EDITOR $HOME/.gitconfig"
alias zshrc="open -a $TEXT_EDITOR $HOME/.zshrc"
alias scripts="open -a $TEXT_EDITOR $WORKING_DIR/scripts"

# Commands
alias ll:s="du -sh * | sort -hr"

# Updates and cleanups
alias brew:update="brew update && brew cleanup; brew doctor"
alias node:clear="find . -name "node_modules" -exec rm -rf '{}' +"
