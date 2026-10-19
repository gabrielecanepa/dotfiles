# npm-global plugin

Wraps the `npm` command to automatically track global npm packages in a `package.json`.

To use it, add `npm-global` to the plugins array in your zshrc file:

```zsh
plugins=(... npm-global)
```

## Usage

| Command                | Description                                                 |
| ---------------------- | ----------------------------------------------------------- |
| `npm dump`             | Write the manifest from the installed global dependencies   |
| `npm fresh`            | Update every global dependency and dump the manifest        |
| `npm fresh -i`         | Run an interactive update with `taze` and dump the manifest |
| `npm install --global` | Install every dependency specified in the manifest          |

Any other `npm` command is passed through unchanged.

Tab completion includes npm's commands and arguments, plus `dump` and `fresh` (`-i` or `--interactive`).

When [nodenv](https://github.com/nodenv/nodenv) is installed, a successful global `install`, `uninstall`, or `update` rehashes the nodenv shims, so all installed binaries become immediately available under the current Node.js version.

`npm fresh -i` runs [taze](https://github.com/antfu-collective/taze) with `npx` and updates the manifest after the interactive update is complete.

## Settings

- `NPM_GLOBAL_DIR`: directory storing the global `package.json`. Defaults to `~/.npm`.
