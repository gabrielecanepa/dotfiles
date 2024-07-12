#!/bin/sh

CONFIG_FILES="
  .aliases
  .bash_profile
  .bashrc
  .jobs
  .profile
"
SCRIPT_REGEX="(\.sh$|\.husky/*)"

scripts="$(cd "$HOME" && git ls-files --cached --others --exclude-standard | grep -E "$SCRIPT_REGEX")"
exit=0

while read -r file; do
  [ -z "$file" ] && continue
  ! shellcheck "$HOME/$file" && exit=1
done << EOF
  $CONFIG_FILES $scripts
EOF

return $exit
