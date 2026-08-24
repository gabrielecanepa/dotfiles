# filesystem plugin

Aliases and helpers to list files, inspect directory sizes, print `PATH` and `FPATH`, and create or remove directories.

To use it, add `filesystem` to the plugins array in your zshrc file:

```zsh
plugins=(... filesystem)
```

## Usage

| Command           | Description                                                                |
| ----------------- | -------------------------------------------------------------------------- |
| `ls`              | `gls` when installed (hiding Finder metadata), colored `/bin/ls` otherwise |
| `ll`              | Long listing including hidden files                                        |
| `lss [<dir>...]`  | Directory sizes one level deep, sorted largest first                       |
| `path`            | Print `PATH`, one entry per line                                           |
| `fpath`           | Print `FPATH`, one entry per line                                          |
| `rmm <name>...`   | Recursively remove every directory matching each name under the cwd        |
| `mkdircd <dir>`   | Create a directory and `cd` into it                                        |
| `mkdircode <dir>` | Create a directory and open it in VS Code                                  |
