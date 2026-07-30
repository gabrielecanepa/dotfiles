---
description: 'Use for LaunchAgent templates and their dotfiles renderer: portable placeholders, labels, enabled state, absolute rendered paths, safe retirement, and performance.'
applyTo: '.config/launchd/**,.install.sh,.zsh/plugins/dotfiles/**'
paths:
  - '.config/launchd/**'
  - '.install.sh'
  - '.zsh/plugins/dotfiles/**'
---

# LaunchAgent templates

- `.config/launchd/*.plist` files are tracked templates with literal `$HOME` and `$HOMEBREW_PREFIX`. `dotfiles init` renders them into `~/Library/LaunchAgents`, reloads changes, and `dotfiles doctor` reports drift. Edit templates, never generated files.
- The filename stem must equal `Label`. launchd expands nothing at runtime, so rendered paths are absolute; `~` and bare binary names fail with `EX_CONFIG` (78).
- `Disabled` is the declarative switch. Active templates use `<false/>`; `<true/>` makes the next init unload the job and remove its generated plist. Do not use `launchctl enable` or `disable`, whose external state overrides the template.
- Init never deletes unknown generated agents. Retire one with `launchctl bootout gui/$UID/<label>` and remove its generated plist manually.
- Do not set `ProcessType` to `Background`; it pins the job and its children to efficiency cores, roughly 3.5x slower. Omit the key.
