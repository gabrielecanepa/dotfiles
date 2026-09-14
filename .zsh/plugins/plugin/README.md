# plugin plugin

Loads, reloads, and updates zsh plugins.

To use it, add `plugin` to the plugins array in your zshrc file:

```zsh
plugins=(... plugin)
```

## Usage

```zsh
plugin load <name...>
plugin update [name...]
```

`load` sources `$ZSH_CUSTOM/plugins/<name>/<name>.plugin.zsh` for each name, falling back to `$ZSH/plugins/<name>/<name>.plugin.zsh`.

`update` fetches the latest commit for each custom plugin containing a `.git` directory.

Commands and plugin names are autocompleted.
