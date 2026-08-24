# brewfile plugin

Wraps [`brew`](https://brew.sh) and [`mas`](https://github.com/mas-cli/mas) so every package-mutating command syncs the Brewfile in the background and adds `brew bundle` shortcuts.

To use it, add `brewfile` to the plugins array in your zshrc file:

```zsh
plugins=(... brewfile)
```

## Usage

| Command       | Description                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------------ |
| `brew dump`   | Dump the installed brews, casks, taps, and App Store apps to the Brewfile                        |
| `brew fresh`  | Update, upgrade everything (`--no-casks` and `--no-mas` to skip), clean up, dump, and run doctor |
| `brew global` | Run `brew bundle` against the global Brewfile                                                    |
| `brew check`  | Verify that everything in the Brewfile is installed                                              |
| `brew reset`  | Run `brew update-reset`                                                                          |

Any other `brew` or `mas` subcommand is passed through unchanged. After a successful mutating command (`install`, `uninstall`, `upgrade`, `tap`, and friends) the Brewfile is re-dumped in a detached background job, so the prompt returns immediately. `mas install`, `mas uninstall`, and `mas upgrade` must run under `sudo`.
