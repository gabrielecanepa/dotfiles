---
name: sweep-macos
description: >-
  Audit macOS for leftover data from uninstalled applications and stage reversible wipes. Use for /sweep-macos or questions about orphaned app data, leftovers from deleted apps, app residue, or reclaiming disk space from old caches and preferences.
disable-model-invocation: true
allowed-tools: Bash(~/.agents/skills/sweep-macos/scripts/sweep-macos.sh *)
---

# sweep-macos

Audit the machine for data whose owning application is gone, report it in four actionable buckets, and wipe only through a reversible, confirmed path. The detector encodes hard-won rules from a manual run; read [references/detection.md](references/detection.md) before changing classification logic, and follow it when explaining a classification to the user.

Buckets: CONFIDENT (no owner, untouched past the cutoff), VERIFY (no owner but ambiguous, needs human eyes), CACHES (regenerable data of live tools), REPORT (informational, never wiped), LIVE (excluded, shown so the exclusions can be audited).

## Arguments

Parse optional arguments from the user request:

- `--xdg`: also scan `~/.cache`, `~/.config`, `~/.local/share`, `~/.local/state`, and untracked `$HOME` dotdirs. Include it when the user mentions dev tools, dotfiles, or XDG data.
- `--no-system`: skip `/Library` and `/Users/Shared`.
- `--days N`: cold cutoff, default 90.
- `--min-size-mb N`: report table floor, default 1. Smaller items still land in report.tsv and are still wiped when their bucket is.

## Workflow

### 1. Audit

Run the bundled script with a generous timeout (a full scan walks most of `~/Library` and takes minutes):

```bash
~/.agents/skills/sweep-macos/scripts/sweep-macos.sh audit [flags]
```

The script is read-only, prints progress to stderr, and prints the run directory on stdout. It writes `report.md`, `report.tsv`, `report.json`, and the `live-*` set files into that directory under `${XDG_STATE_HOME:-~/.local/state}/sweep-macos/`.

### 2. Summarize

Read `report.md` from the run directory. Render in chat, in this order: per-bucket totals, the CONFIDENT table, the VERIFY table, the CACHES table, any gaps (paths the audit could not read, usually Full Disk Access), and one line on how many LIVE exclusions and Apple-system skips there were, pointing at the report file for the full lists. Keep row reasons intact; they are the user's evidence.

### 3. Confirm

Never wipe anything without this step. Use AskUserQuestion:

1. One question to authorize the apply step at all, stating what CONFIDENT auto-wipe means: those items move to the Trash automatically once apply is authorized.
2. For VERIFY rows, group by vendor or family into multi-select questions so the user picks what goes. Present size and reason per group.
3. For CACHES rows, ask per item; each answer trades disk space against a re-download or rebuild.

Write every approved VERIFY and CACHES path, exactly as shown in the report's Path column, one per line, to an approved file in the run directory.

### 4. Apply

```bash
~/.agents/skills/sweep-macos/scripts/sweep-macos.sh apply --run RUN_DIR [--approved FILE]
```

Moves are never deletions: user paths go to `~/.Trash/sweep-macos-<run>/`, system paths move via `sudo mv` into `staged-system/` inside the run directory, and every move is appended to `manifest.tsv`. If system rows are selected and the session has no TTY for the sudo prompt, do not let apply die mid-run: run apply for user paths first (approve only user paths), then hand the user the full command to run themselves with the `!` prefix.

### 5. Report back

State items moved, space staged, the manifest path, and the restore command. Note that freed space appears in Finder once the Trash is emptied and local Time Machine snapshots thin out.

### 6. Restore

```bash
~/.agents/skills/sweep-macos/scripts/sweep-macos.sh restore --run RUN_DIR [PATH...]
```

Replays the manifest in reverse, everything or only the given original paths. Offer it whenever the user reports something broke after a wipe.

## Safety rules

- Nothing is ever `rm`'d. The script moves data and keeps a manifest; treat any impulse to shortcut this with `rm` as a bug.
- REPORT rows are never wipe candidates: receipts under `/var/db/receipts` are the only trace of what a pkg installed, and deleting an orphaned iCloud container removes the data from iCloud on every device.
- XDG and dotdir findings never reach CONFIDENT; ownership there is heuristic, so they are wiped only through explicit per-item approval.
- Keychains, Mail, Messages, Photos, `CloudStorage`, and `com.apple.*` data are structurally out of scope; the scanner never lists them. Apple stock content (GarageBand, Logic, Apple Loops) is the one exception and always lands in VERIFY.
- Audit never elevates. sudo appears only inside apply and restore, per move, for paths outside `$HOME`.
- Report gaps honestly: if Full Disk Access or sudo was missing, the affected paths are listed as gaps, not silently skipped.
