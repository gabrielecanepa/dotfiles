xcode-select() 
{
  case $1 in
    reset)
      if [ "$2" ]; then
        echo "${fg[red]}Unknown option: $2$reset_color"
        return 1
      fi
      echo "${fg[yellow]}This will remove and reinstall the Xcode Command Line Tools$reset_color\n"
      printf "Are you sure you want to continue? (y/N) "
      read -r choice
      if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
        sudo rm -rf $(xcode-select -print-path)
        command xcode-select --install
      fi
      ;;
    *)
      command xcode-select $@
      ;;
  esac
}
