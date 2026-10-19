# Brewfile plugin

Wraps the [`brew`](https://brew.sh) and [`mas`](https://github.com/mas-cli/mas) CLIs to automatically sync the global Brewfile in background.

To use it, add `brewfile` to the plugins array in your zshrc file:

```zsh
plugins=(... brewfile)
```

## Usage

| Command       | Description                                                                             |
| ------------- | --------------------------------------------------------------------------------------- |
| `brew dump`   | Dump the installed brews, casks, taps, and App Store apps to the global Brewfile        |
| `brew fresh`  | Update and upgrade (or use `--no-casks` and `--no-mas`), clean up, dump, and run doctor |
| `brew global` | Run `brew bundle` against the global Brewfile                                           |
| `brew check`  | Verify that everything in the Brewfile is correctly installed                           |
| `brew reset`  | Alias of `brew update-reset`                                                            |

Any other `brew` or `mas` subcommand is passed unchanged. After a successful writing command (`install`, `uninstall`, `upgrade`, `tap`, etc.) the Brewfile is dumped in a detached background job and the prompt returns immediately.

`mas install`, `mas uninstall`, and `mas upgrade` run under `sudo`.

## Settings

- `HOMEBREW_BUNDLE_FILE_GLOBAL`: path to a custom global Brewfile. If not set, Homebrew checks `${XDG_CONFIG_HOME}/homebrew/Brewfile`, `~/.homebrew/Brewfile`, and `~/.Brewfile`.
