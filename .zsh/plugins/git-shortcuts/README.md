# git-shortcuts plugin

Creates short shell aliases from the user-defined Git aliases, compacting each `git <alias>` command into a `g<alias>` shortcut.

To use it, add `git-shortcuts` to the plugins array in your zshrc file:

```zsh
plugins=(... git-shortcuts)
```

## Usage

Given this Git configuration:

```properties
[alias]
  a = add
  cm = commit -m
  pristine = !git reset --hard && git clean -df
  st = status -sb
  undo = reset --soft HEAD^
```

the first prompt defines:

| Shortcut    | Git alias      | Command                             |
| ----------- | -------------- | ----------------------------------- |
| `ga`        | `git a`        | `git add`                           |
| `gcm`       | `git cm`       | `git commit -m`                     |
| `gpristine` | `git pristine` | `git reset --hard && git clean -df` |
| `gst`       | `git st`       | `git status -sb`                    |
| `gundo`     | `git undo`     | `git reset --soft HEAD^`            |

Each shortcut resolves to the Git alias instead of expanding it, so editing the Git configuration updates the shortcuts too.

Names already taken by a command, function, or alias are skipped.

## Settings

Set these before the first prompt:

- `GIT_SHORTCUTS_PREFIX`: string prepended to every shortcut. Defaults to `g`.
- `GIT_SHORTCUTS_MIN_LENGTH`: shortest Git alias to mirror. Defaults to `1` and must be at least `1`.
- `GIT_SHORTCUTS_MAX_LENGTH`: longest Git alias to mirror. Defaults to `-1`, meaning no limit. Any other value must be at least `2` and not below the minimum.
- `GIT_SHORTCUTS_INCLUDE`: array of Git aliases to always mirror, even if not within the min/max length.
- `GIT_SHORTCUTS_EXCLUDE`: array of Git aliases to never mirror.

For example, this setup applied to the configuration above:

```zsh
GIT_SHORTCUTS_PREFIX=@
GIT_SHORTCUTS_MIN_LENGTH=2
GIT_SHORTCUTS_MAX_LENGTH=6
GIT_SHORTCUTS_INCLUDE=(pristine)
GIT_SHORTCUTS_EXCLUDE=(undo)
```

produces these shortcuts:

| Git alias  | Shortcut    | Reason                              |
| ---------- | ----------- | ----------------------------------- |
| `a`        | none        | shorter than `2`                    |
| `cm`       | `@cm`       |                                     |
| `pristine` | `@pristine` | too long but listed in the includes |
| `st`       | `@st`       |                                     |
| `undo`     | none        | in range but listed in the excludes |
