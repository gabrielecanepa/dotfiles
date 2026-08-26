# dotfiles plugin

Re-asserts machine state that drifts, such as git hooks paths, clobbered symlinks, Obsidian vault links, launch agents, VS Code extensions, and npm globals. It also completes the shell startup by initializing the path and sourcing the aliases file.

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

`init` runs on every shell startup from the zshrc. The npm globals checks activate only when the `npm-global` plugin is loaded.

## Settings

- `OBSIDIAN_VAULT`: exact name of the vault folder in the iCloud Obsidian container. When set, `~/.vault` is linked to that folder.
- `ZSH_ALIASES`: path to the aliases file sourced by `init`, defaults to `~/.aliases`.
