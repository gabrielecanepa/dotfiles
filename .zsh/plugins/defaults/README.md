# defaults plugin

Wraps the [`defaults`](https://ss64.com/mac/defaults.html) CLI to list, save, sync, and refresh macOS preferences in a single configuration file.

To use it, add `defaults` to the plugins array in your zshrc file:

```zsh
plugins=(... defaults)
```

## Usage

| Command                   | Description                                                   |
| ------------------------- | ------------------------------------------------------------- |
| `defaults dump`           | Write the configuration file with the current system values   |
| `defaults dump --dry-run` | Preview what `dump` would apply                               |
| `defaults load`           | Apply the configuration and restart the affected applications |
| `defaults list`           | Print the saved configuration                                 |

Any other subcommand is passed to `defaults` unchanged.

When the configuration is empty or missing, `dump` creates it using the values specified in `settings.txt`. To track something new, add the value to the configuration by hand and the plugin will update it with the current system value.

## Settings

- `MACOS_DEFAULTS`: path to the preferences file. Defaults to `${XDG_CONFIG_HOME:-$HOME/.config}/macos/defaults.sh`.
