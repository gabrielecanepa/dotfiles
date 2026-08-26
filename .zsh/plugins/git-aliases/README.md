# git-aliases plugin

Turns installed Git aliases into shorter prefixed aliases, so each `git <alias>` command gets a `g<alias>` shortcut. Aliases are built once on the first prompt.

To use it, add `git-aliases` to the plugins array in your zshrc file:

```zsh
plugins=(... git-aliases)
```

## Usage

Given these Git aliases:

```properties
[alias]
  a = add
  cm = commit -m
  reset-origin = !git remote remove origin &>/dev/null && git remote add origin
  st = status -sb
  sweep = !git fetch -p && git for-each-ref --format '%(refname:short) %(upstream:track)' | awk '$2 == "[gone]" {print $1}' | xargs -r git branch -D
  undo = reset --soft HEAD^
```

the first prompt defines:

| Shortcut        | Git alias          | Command                                       |
| --------------- | ------------------ | --------------------------------------------- |
| `ga`            | `git a`            | `git add`                                     |
| `gcm`           | `git cm`           | `git commit -m`                               |
| `greset-origin` | `git reset-origin` | replaces the `origin` remote                  |
| `gst`           | `git st`           | `git status -sb`                              |
| `gsweep`        | `git sweep`        | deletes local branches whose upstream is gone |
| `gundo`         | `git undo`         | `git reset --soft HEAD^`                      |

Each alias resolves to the Git alias instead of expanding it, so editing the Git configuration updates the shortcuts too. Names already taken by a command, function, or alias are skipped.

## Settings

Set these before the first prompt, for example in `~/.zshrc`:

- `ZSH_GIT_ALIASES_PREFIX`: string prepended to every mirrored name. Defaults to `g`.
- `ZSH_GIT_ALIASES_MIN_LENGTH`: shortest Git alias to mirror. Defaults to `1` and must be at least `1`.
- `ZSH_GIT_ALIASES_MAX_LENGTH`: longest Git alias to mirror. Defaults to `-1`, meaning no limit. Any other value must be at least `2` and not below the minimum.
- `ZSH_GIT_ALIASES_IGNORE`: array of Git aliases to never mirror.

Wrong lengths report an error on the first prompt and no aliases are built.

For example, this setup applied to the configuration above:

```zsh
ZSH_GIT_ALIASES_PREFIX="git"
ZSH_GIT_ALIASES_MIN_LENGTH=2
ZSH_GIT_ALIASES_MAX_LENGTH=6
ZSH_GIT_ALIASES_IGNORE=(undo)
```

produces these shortcuts:

| Git alias      | Shortcut   | Skipped reason                  |
| -------------- | ---------- | ------------------------------- |
| `a`            |            | shorter than the minimum of `2` |
| `cm`           | `gitcm`    |                                 |
| `reset-origin` |            | longer than the maximum of `6`  |
| `st`           | `gitst`    |                                 |
| `sweep`        | `gitsweep` |                                 |
| `undo`         |            | listed in the ignore array      |
