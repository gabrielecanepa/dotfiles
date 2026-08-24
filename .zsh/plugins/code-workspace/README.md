# code-workspace plugin

Opens a [VS Code workspace](https://code.visualstudio.com/docs/editor/workspaces) by name from the workspaces directory.

To use it, add `code-workspace` to the plugins array in your zshrc file:

```zsh
plugins=(... code-workspace)
```

## Usage

```zsh
code-workspace <name>
```

Opens `<name>.code-workspace` from the workspaces directory. Workspace names are completed.

## Settings

- `VSCODE_WORKSPACES_PATH`: directory holding the `.code-workspace` files. Defaults to `~/.vscode/workspaces`.
