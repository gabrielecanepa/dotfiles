# plugin utility

Loads, reloads, and updates Zsh plugins.

To use it, add `plugin` to the plugins array in your zshrc file:

```zsh
plugins=(... plugin)
```

## Usage

| Command                     | Description                                          |
| --------------------------- | ---------------------------------------------------- |
| `plugin load <name>...`     | Load one or more plugins                             |
| `plugin update [<name>...]` | Update one or more plugins, or all if none specified |

`load` sources `$ZSH_CUSTOM/plugins/<name>/<name>.plugin.zsh` and falls back to `$ZSH/plugins/<name>/<name>.plugin.zsh`.

`update` fetches the latest commit of each custom plugin containing a `.git` directory and applies a fast-forward update. It refuses uncommitted changes or diverged history instead of discarding local work.

Commands and plugin names are autocompleted.
