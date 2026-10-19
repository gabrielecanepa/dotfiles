# lts plugin

Finds, checks, and installs the latest release of Node.js, Python, or Ruby with long-term support (LTS).

```zsh
plugins=(... lts)
```

For installations, the plugin requires [`nodenv`](https://github.com/nodenv/nodenv), [`pyenv`](https://github.com/pyenv/pyenv), or [`rbenv`](https://github.com/rbenv/rbenv) to be available in the `PATH`.

## Usage

| Command                                                                      | Description                                                                 |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `lts <language>[@<prefix>]`                                                  | Print the latest LTS release, optionally matching a prefix                  |
| `lts check [<language>]`                                                     | Compare the active version against the latest LTS, for one or all languages |
| `lts install [<language>[@<prefix>]...]`, `lts i [<language>[@<prefix>]...]` | Install the latest LTS of all supported languages or the specified ones     |

## Examples

```zsh
lts node                   # print latest stable node release
lts node@18                # print latest stable node 18 minor release
lts check                  # compare active versions against latest stable releases
lts install python ruby@2  # install latest stable python and ruby 2 versions
```
