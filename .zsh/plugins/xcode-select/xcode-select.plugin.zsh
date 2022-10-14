xcode-select()
{
  case $1 in
    --reset)
      if [ "$2" ]; then
        echo "${fg[red]}Unknown option: $2$reset_color"
        return 1
      fi

      echo "${fg[yellow]}warning$reset_color This will remove and reinstall the Xcode Command Line Tools"
      printf "Are you sure you want to continue? (y/N) "
      read -r choice
      echo "\n"

      if [[ "${choice:l}" = "y" ]]; then
        sudo rm -rf "$(xcode-select -print-path)"
        echo "xcode-select: note: command line tools removed"
        xcode-select --install
      else
        echo "xcode-select: note: operation aborted"
      fi
      ;;

    *)
      command xcode-select $@
      ;;
  esac
}
