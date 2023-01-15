#!/bin/zsh

# function brew() {
#   local function dump_brewfile() {
#     printf "${fg[blue]}==>${reset_color} Updating Brewfile"
#     brew dump
#     echo "\r"
#   }

#   case $1 in
#     dump)
#       command brew bundle dump --force --describe --cleanup
#       ;;
#     init)
#       if [[ -f "$HOMEBREW_BUNDLE_FILE" ]]; then
#         printf "${fg[yellow]}A Brewfile already exists. Do you want to override it with your current configuration? [y/N]$reset_color "
#         read -r -k 1 choice
#         case "$choice" in
#           [yY])
#             rm -f "$HOMEBREW_BUNDLE_FILE" "${HOMEBREW_BUNDLE_FILE}.lock.json"
#             brew dump
#             ;;
#           [nN$'\n'])
#             ;;
#           *)
#             echo "${fg[red]}Unknown option: $choice$reset_color"
#             unset choice
#             return 1
#             ;;
#         esac
#         unset choice
#       else
#         brew dump
#       fi
#       command brew bundle
#       ;;
#     install|uninstall|tap|untap)
#       command brew $@
#       [[ $? -eq 0 ]] && dump_brewfile
#       ;;
#     *)
#       command brew $@
#       ;;
#   esac
# }

function brew() {
  case "$1" in
    install|uninstall|upgrade|tap|untap)
      if command brew $@; then
        printf "${fg[blue]}==>${reset_color} Updating Brewfile"
        command brew bundle dump --global --force --describe --cleanup
        echo "\r"
      fi
      ;;
    *)
      command brew $@
      ;;
  esac
}
