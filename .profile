#/bin/sh

# Load ~/.zprofile if not already loaded.

_VARS=(
  NAME
  EMAIL
  WORKING_DIR
  EDITOR
  GIT_EDITOR
)

for _var in "${_VARS[@]}"; do
  if [ -z "$(eval echo \$$_var)" ]; then
    source "$HOME/.zprofile"
    break
  fi
done; unset var

unset _VARS
