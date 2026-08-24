# deps plugin

Prints the dependencies declared in a project's `package.json`, one per line.

To use it, add `deps` to the plugins array in your zshrc file:

```zsh
plugins=(... deps)
```

Requires [`jq`](https://jqlang.org).

## Usage

```zsh
deps [<dir>|<path/to/package.json>] [options]
```

With no path, reads `package.json` from the current directory.

| Option         | Description                                          |
| -------------- | ---------------------------------------------------- |
| `-L`, `--list` | Print the dependencies on a single line              |
| `--dev`        | Include `devDependencies`                            |
| `--peer`       | Include `peerDependencies`                           |
| `--optional`   | Include `optionalDependencies`                       |
| `--all`        | Include every group (exclusive with the flags above) |
