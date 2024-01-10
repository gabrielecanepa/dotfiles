#/bin/sh

# Load .zprofile if not already loaded.
if [[ -z "$NAME" && -z "$EMAIL" && -z "$WORKING_DIR" && -z "$EDITOR" && -z "$GIT_EDITOR" && -f "$HOME/.zprofile" ]]; then
  source "$HOME/.zprofile"
fi
