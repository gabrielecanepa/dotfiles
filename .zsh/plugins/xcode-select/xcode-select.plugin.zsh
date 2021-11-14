xcode-select() 
{
  case $1 in
    reset)
      if [ "$2" ]; then
        echo "${fg[red]}Unknown option: $2$reset_color"
        return
      fi
      echo "${fg[yellow]}This will remove and reinstall theXcode Command Line Tools$reset_color\n"
      printf "Are you sure you want to continue? (y/N) "
      read -r choice
      if [[ "$choice" =~ [yY] ]]; then
        sudo rm -rf $(xcode-select -print-path)
        xcode-select --install
      fi
      ;;
    *)
      command xcode-select $@
      ;;
  esac
}
