#/bin/sh

# Load .zprofile if not already loaded.
if [[ -z "$NAME" || -z "$EMAIL" && -f "$HOME/.zprofile" ]]; then
  source "$HOME/.zprofile"
fi
