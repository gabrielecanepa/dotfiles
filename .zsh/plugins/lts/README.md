# lts plugin

Finds and installs the latest LTS release of Node.js, Python, or Ruby through the version managers [`nodenv`](https://github.com/nodenv/nodenv), [`pyenv`](https://github.com/pyenv/pyenv), and [`rbenv`](https://github.com/rbenv/rbenv). Node.js also requires [`jq`](https://jqlang.org).

To use it, add `lts` to the plugins array in your zshrc file:

```zsh
plugins=(... lts)
```

## Usage

| Command                          | Description                                                                 |
| -------------------------------- | --------------------------------------------------------------------------- |
| `lts <language[@prefix]>`        | Print the latest LTS release matching an optional version prefix            |
| `lts check [language]`           | Compare the active version against the latest LTS, for one or all languages |
| `lts install`                    | Install the latest LTS of all supported languages                           |
| `lts install <spec>...`, `lts i` | Install the latest LTS matching each `language[@prefix]` spec               |

## Examples

```zsh
lts node                   # latest Node.js LTS release
lts node@18                # latest minor LTS version of Node.js 18
lts check                  # compare every active version against its latest LTS
lts install python ruby@2  # install the latest Python LTS and Ruby 2 release
```
