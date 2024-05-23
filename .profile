#!/bin/sh

# Load ~/.zprofile if not already loaded.

VARS="NAME EMAIL WORKING_DIR EDITOR GIT_EDITOR"

for var in $VARS; do
  echo "Checking $var"
  if [ -z "$(eval echo \$"$var")" ]; then
    . "$HOME/.zprofile"
    break
  fi
done

unset VARS var
