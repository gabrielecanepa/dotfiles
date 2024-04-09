#/bin/sh

# Load ~/.zprofile if not already loaded.

VARS=(
  NAME
  EMAIL
  WORKING_DIR
  EDITOR
  GIT_EDITOR
)

for var in "${VARS[@]}"; do
  if [ -z "$(eval echo \$$var)" ]; then
    source "$HOME/.zprofile"
    break
  fi
done
