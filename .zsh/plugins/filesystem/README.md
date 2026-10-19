# filesystem plugin

Aliases and helpers to list and manage files, directories, and paths.

To use it, add `filesystem` to the plugins array in your zshrc file:

```zsh
plugins=(... filesystem)
```

## Usage

| Command           | Description                                                 |
| ----------------- | ----------------------------------------------------------- |
| `ls`              | Uses `gls` if installed or colored `/bin/ls` otherwise      |
| `ll`              | Long listing including hidden files                         |
| `lss [<dir>...]`  | Sort largest files first                                    |
| `path`            | Print `PATH`, one entry per line                            |
| `fpath`           | Print `FPATH`, one entry per line                           |
| `rmm [<name>...]` | Recursively remove every directory matching the given names |
| `mkdircd <dir>`   | Create a directory and `cd` into it                         |
| `~icloud`         | Named directory for iCloud Drive, defined only if available |
