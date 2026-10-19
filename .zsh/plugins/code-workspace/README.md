# code-workspace plugin

Autocompletes and opens [VS Code workspaces](https://code.visualstudio.com/docs/editor/workspaces) by name from the given workspaces directory.

To use it, add `code-workspace` to the plugins array in your zshrc file:

```zsh
plugins=(... code-workspace)
```

## Usage

```zsh
code-workspace <name>
```

Opens `<name>.code-workspace` from the workspaces directory.

## Settings

- `VSCODE_WORKSPACES_DIR`: directory storing the `.code-workspace` files. Defaults to `$HOME/.vscode/workspaces`.
