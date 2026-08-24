# gatekeeper plugin

Manages macOS [Gatekeeper](https://support.apple.com/guide/security/gatekeeper-and-runtime-protection-sec5599b66df/web): check or toggle it globally, or strip the quarantine attribute from specific apps and files.

To use it, add `gatekeeper` to the plugins array in your zshrc file:

```zsh
plugins=(... gatekeeper)
```

## Usage

| Command                          | Description                                                  |
| -------------------------------- | ------------------------------------------------------------ |
| `gatekeeper status`              | Print the current status, suggesting to enable when disabled |
| `gatekeeper enable`              | Enable Gatekeeper globally                                   |
| `gatekeeper disable`             | Disable Gatekeeper globally                                  |
| `gatekeeper disable <path>...`   | Strip quarantine from the given files or directories         |
| `gatekeeper disable -a <app>...` | Strip quarantine from the named `/Applications` bundles      |
| `gatekeeper help`                | Show the help message                                        |

On macOS 15 and later Gatekeeper cannot be re-enabled from the CLI, `enable` points to System Settings instead.
