# quarantine plugin

Manages the macOS `com.apple.quarantine` attribute on files and directories.

To use it, add `quarantine` to the plugins array in your zshrc file:

```zsh
plugins=(... quarantine)
```

## Usage

| Command                             | Description                                 |
| ----------------------------------- | ------------------------------------------- |
| `quarantine status [-v] <path>...`  | Print the quarantine status                 |
| `quarantine remove [-r] <path>...`  | Remove the quarantine attributes            |
| `quarantine restore [-r] <path>...` | Restore the quarantine attributes           |
| `quarantine set <raw-value> <path>` | Set a quarantine attribute from a raw value |
| `quarantine help`                   | Show usage information                      |

The `-r`/`--recursive` flag includes the whole content of the specified directory or application bundle. `-v`/`--verbose` prints the raw attribute value in addition to the status.

Removed attributes are stored in `${XDG_STATE_HOME:-$HOME/.local/state}/quarantine`.
