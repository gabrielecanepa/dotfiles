if [[ $OSTYPE == darwin* ]]; then
  command zsh ${0:A:h}/reconcile.zsh \
    ${LAUNCHD_DIR:-${XDG_CONFIG_HOME:-~/.config}/launchd} \
    ${XDG_STATE_HOME:-~/.local/state}/launchd &|
fi
