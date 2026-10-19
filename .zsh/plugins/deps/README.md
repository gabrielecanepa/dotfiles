# deps plugin

Prints the dependencies declared in a project's `package.json`.

To use it, add `deps` to the plugins array in your zshrc file:

```zsh
plugins=(... deps)
```

Requires [`jq`](https://jqlang.org).

## Usage

```zsh
deps [<dir>|<path/to/package.json>] [options]
```

| Option         | Description                                          |
| -------------- | ---------------------------------------------------- |
| `-L`, `--list` | Print the dependencies on a single line              |
| `--dev`        | Include `devDependencies`                            |
| `--peer`       | Include `peerDependencies`                           |
| `--optional`   | Include `optionalDependencies`                       |
| `--all`        | Include every group (exclusive with the flags above) |

With no path specified, it reads `package.json` from the current directory.
