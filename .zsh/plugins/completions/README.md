# completions plugin

Generates and caches zsh completion files for CLIs that can emit their own (`<cli> completion zsh` and common variants).

To use it, add `completions` to the plugins array in your zshrc file:

```zsh
plugins=(... completions)
```

## Usage

```zsh
completions <cli> [<cli> ...]             # calls each CLI and cache its completion file
<cli> completion zsh | completions <cli>  # cache completion text from stdin
```

Cached files are written as `_<cli>` under the completions directory, and rewritten only when the generated output changes.

## Settings

- `ZSH_COMPLETIONS`: array of CLIs to keep cached. At startup, missing completions are generated inline so they work in the current session. Existing caches are run in a detached background job.
- `ZSH_COMPLETIONS_PATH`: cache directory. Defaults to `$ZSH_CUSTOM/completions`.
