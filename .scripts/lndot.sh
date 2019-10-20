lndot() {
  for file in $@
    ln -s $WORKING_DIR/$USER/dotfiles/$file $file
}
