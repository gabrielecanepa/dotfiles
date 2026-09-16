# dotfiles plugin

Re-asserts machine state that drifts, such as launch agents, VS Code extensions, npm globals, and Homebrew packages. It also completes the shell startup by initializing the path and sourcing the aliases file.

To use it, add `dotfiles` to the plugins array in your zshrc file:

```zsh
plugins=(... dotfiles)
```

## Usage

| Command                         | Description                                                          |
| ------------------------------- | -------------------------------------------------------------------- |
| `dotfiles init [-v\|--verbose]` | Fix any drifted state, silently unless verbose (default; idempotent) |
| `dotfiles doctor`               | Report drift without changing anything                               |
| `dotfiles help`                 | Show the help message                                                |

`init` runs on every shell startup from the zshrc.

## Reconcilers

`init` and `doctor` walk `ZSH_DOTFILES_RECONCILERS` and call `_<name>_reconcile` and `_<name>_drift`, with every hyphen in the name replaced by an underscore. Both lookups are guarded, so a reconciler whose plugin is not loaded is skipped rather than failing.

| Reconciler   | Defined in            | Fixed by `init` |
| ------------ | --------------------- | --------------- |
| `launchd`    | `reconcilers/`        | yes             |
| `vscode`     | `reconcilers/`        | yes             |
| `npm-global` | `npm-global` plugin   | no              |
| `brewfile`   | `brewfile` plugin     | no              |

A reconciler whose tool already owns a plugin lives in that plugin, next to the settings and helpers it shares. The rest have no shell-facing command of their own and are sourced from `reconcilers/` in this directory.

Defining only `_<name>_drift` makes a reconciler report-only: `doctor` surfaces it and `init` skips it. That is how a check too slow for shell startup stays out of it.

### Contract

- `_<name>_drift` prints one `<state> <item>` line per problem and returns 0. `doctor` groups the lines by state, so the states are free-form.
- `_<name>_reconcile [verbose]` fixes what it can, logs through `_zsh::log`, and returns non-zero only when something failed.

## Settings

- `ZSH_ALIASES`: path to the aliases file sourced by `init`, defaults to `~/.aliases`.
- `ZSH_DOTFILES_RECONCILERS`: reconcilers to run, in order. Defaults to `(launchd vscode npm-global brewfile)`.
