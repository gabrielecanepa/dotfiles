# Bare zsh-<version> prompt with no segments or hooks, for debugging the shell
# without prompt machinery; sourcing it clears the previous theme's hooks.

source ${0:A:h}/lib/hooks.zsh

PROMPT='zsh-${ZSH_VERSION}$ '
RPROMPT=
