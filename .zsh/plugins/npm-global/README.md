# npm-global plugin

Tracks npm global packages in a `package.json` manifest and reinstalls them on demand by wrapping `npm`, so every global mutating command keeps the manifest in sync.

To use it, add `npm-global` to the plugins array in your zshrc file:

```zsh
plugins=(... npm-global)
```

## Usage

| Command                | Description                                                          |
| ---------------------- | -------------------------------------------------------------------- |
| `npm dump`             | Rewrite the manifest from the installed globals (offline and atomic) |
| `npm fresh`            | Update every global package, then dump                               |
| `npm fresh -i`         | Pick updates interactively with `npx taze`, then dump                |
| `npm install --global` | With no package named, reinstall everything tracked in the manifest  |

Any other `npm` command is passed through unchanged. After a successful global `install`, `uninstall`, or `update` (any spelling npm accepts) the nodenv shims are rehashed and the manifest is re-dumped automatically, so a newly installed binary is on `PATH` right away.

`npm fresh -i` runs [taze](https://github.com/antfu-collective/taze) through `npx` and dumps the manifest after the interactive update is complete.

## Settings

- `NPM_GLOBAL`: directory holding the tracked `package.json`. Defaults to `~/.npm`.
