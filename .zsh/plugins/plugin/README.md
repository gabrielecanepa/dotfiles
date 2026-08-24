# plugin plugin

Loads or reloads a zsh plugin by name, preferring the custom plugin over a default one with the same name.

To use it, add `plugin` to the plugins array in your zshrc file:

```zsh
plugins=(... plugin)
```

## Usage

```zsh
plugin <name>
```

Sources `$ZSH_CUSTOM/plugins/<name>/<name>.plugin.zsh` when it exists, falling back to `$ZSH/plugins/<name>/<name>.plugin.zsh`. Plugin names are autocompleted.
