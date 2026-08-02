# Detection logic

The rules below came out of a manual audit that produced false positives until each one was learned. `scripts/sweep-macos.sh` implements them; keep this file and the script in sync.

## Contents

- [The four traps](#the-four-traps)
- [Liveness sources](#liveness-sources)
- [Matching rules](#matching-rules)
- [Stronger-than-id signals](#stronger-than-id-signals)
- [Buckets](#buckets)
- [Scanned families](#scanned-families)
- [Known limitations](#known-limitations)

## The four traps

1. LaunchServices is not an install oracle. `lsregister -dump` holds stale records for apps deleted weeks earlier. Ground truth is built from actual bundles on disk: `CFBundleIdentifier` read with PlistBuddy, plus `codesign -dv --verbose=2` TeamIdentifier values for team-id-prefixed directories.
2. Two directory families need different matching rules. Group Containers and Application Scripts are keyed by team id (`TEAMID.com.vendor.app`) and `group.` prefixes that do not map to bundle ids, so they get vendor-level prefix matching. Everything else gets strict ancestor matching. One rule for both wrongly flags live apps.
3. An app can change its own bundle id and orphan its own data. Real case: ChatGPT.app reports `com.openai.codex`, so `com.openai.chat` data is genuinely dead even though the app is installed. An id mismatch alone proves neither death nor life; that is why mtime and the VERIFY bucket exist.
4. mtime is the tiebreaker. Helpers whose parent app has a different bundle id (1Password browser support, iA Writer export service) look orphaned by id but have recent mtimes. Anything touched inside the cutoff window goes to VERIFY, never CONFIDENT. The nested-bundle harvest below removes most of this class at the source.

## Liveness sources

- Bundles under `/Applications` (recursive, covers Setapp and vendor subfolders), `~/Applications`, and `/System/Applications`, including nested `.app`, `.appex`, and `.xpc` helpers inside each non-system app. Nested harvesting is what clears trap 4 structurally.
- Team ids from `codesign` on each non-system app.
- App and `CFBundleName` names, normalized (lowercase, spaces, dashes, and underscores stripped), plus vendor tokens (second component of every live bundle id) for human-named directory matching.
- `launchctl list` labels, raw and with `application.` prefixes and trailing numeric segments stripped, and running-app bundle ids from `lsappinfo`. This catches pkg-installed daemons with no bundle under the application roots.
- Receipts whose payload still exists on disk (first files from `pkgutil --files` probed). A receipt alone is not liveness; uninstalled apps leave receipts behind.

## Matching rules

- All matching is case-insensitive: live sets are stored lowercase and candidates are lowercased before lookup (APFS defaults to case-insensitive).
- Strict ancestor matching (`strict_live`): exact id, then each ancestor while more than three components remain, then the direct parent when it still has three or more components. Uses `${p%.*}`, never `awk` field printing, which emits a trailing dot on two-component ids and silently breaks matching.
- Vendor matching (`vendor_live`): first two components, used only for Group Containers, Application Scripts, and `group.`-prefixed keys.
- Team-prefixed keys: match the team id against live teams first, then fall back to vendor matching on the remainder.
- Human-named entries: normalized name against live names and vendor tokens. Plugin-style entries that are bundles get their real `CFBundleIdentifier` read from `Contents/Info.plist` and matched strictly instead.
- Key derivation strips the suffixes `.plist`, `.savedState`, `.binarycookies`, `.xml`, `.lockfile`, ByHost UUID tails, and, in group families, `^[A-Z0-9]{10}\.` and `^groups?\.` prefixes.
- Skipped outright: `com.apple.*`, `systemgroup.*`, `is.workflow.*`, and a curated list of human-named Apple system directories (`write_skip_names` in the script). Skips are counted, not listed, so the report stays readable.
- UUID-named containers (macOS keeps some under UUID directories) resolve their true owner from `MCMMetadataIdentifier` in `.com.apple.containermanagerd.metadata.plist`; a UUID whose metadata is unreadable is system-owned and skipped, never orphaned.
- Generic shared containers named `Caches` (for example `Application Support/Caches` holding per-tool updater caches) are descended one level and their children classified individually; the container itself is never a finding.
- Curated cache paths are excluded from the family scans, so a path appears either in CACHES or as an orphan candidate, never both.

## Stronger-than-id signals

- LaunchAgents and LaunchDaemons: a plist whose `Program` (or `ProgramArguments[0]`) binary is missing is CONFIDENT regardless of mtime; one whose binary exists is LIVE by definition.
- Native messaging host manifests (Chrome, Edge, Firefox; user and system): a `"path"` pointing at a missing binary is CONFIDENT even when the browser is alive.
- Deep mtime, not directory mtime: warmth is decided by the newest file inside the tree, because a directory's own mtime does not change when nested files do.

## Buckets

| Bucket    | Meaning                                                                                   | Wipe path                          |
| --------- | ----------------------------------------------------------------------------------------- | ---------------------------------- |
| CONFIDENT | No owner, cold past the cutoff                                                            | Automatic once apply is authorized |
| VERIFY    | No owner but warm, ambiguous, or Apple stock content                                      | Per-group approval only            |
| CACHES    | Regenerable data of live tools, 100 MB floor                                              | Per-item approval only             |
| REPORT    | Receipts, iCloud containers, system extensions, `/usr/local`, `paths.d`, background items | Never                              |
| LIVE      | Matched an owner; shown so exclusions can be audited                                      | Never                              |

## Scanned families

User: Application Support, Caches, Containers, Group Containers, Application Scripts, Preferences (plus ByHost), HTTPStorages, WebKit, Saved Application State, Logs, Cookies, SyncedPreferences, Internet Plug-Ins, Services, PreferencePanes, Screen Savers, QuickLook, Spotlight, Widgets, Audio/Plug-Ins, Input Methods, Automator, ColorPickers, Keyboard Layouts, PDF Services, Contextual Menu Items, Address Book Plug-Ins, Mail/Bundles, LaunchAgents, and the browser NativeMessagingHosts dirs.

System: Application Support, Preferences, Caches, PrivilegedHelperTools, Extensions, Internet Plug-Ins, PreferencePanes, QuickLook, Audio/Plug-Ins, Input Methods, Frameworks, ScriptingAdditions, Printers, Documentation, Logs, Keyboard Layouts, Java/JavaVirtualMachines, Python, Ruby, LaunchAgents, LaunchDaemons, NativeMessagingHosts, and `/Users/Shared`.

Report-only: `/var/db/receipts`, `~/Library/Mobile Documents` (`iCloud~` containers), `systemextensionsctl list`, `/usr/local`, `/etc/paths.d`, `/etc/manpaths.d`, and `sfltool dumpbtm` when readable.

Deliberately out of scope: Fonts and Sounds (ownership unattributable), `~/Library/Developer` outside the caches list, Keychains, Mail, Messages, Photos, `CloudStorage`, and `DiagnosticReports` (system-managed and auto-pruned).

## Known limitations

- `sfltool dumpbtm` needs sudo; without it the audit records a gap instead of background-item findings.
- Full Disk Access gates Safari, Cookies, Mobile Documents, and some caches; unreadable roots become gaps, never silent skips.
- report.tsv is tab-separated; a path containing a tab would corrupt its row. macOS paths in the scanned families do not contain tabs in practice.
- The launchctl numeric-suffix strip could shorten a label that legitimately ends in digits; the raw label is also kept in the live set, so this only ever widens liveness, never narrows it.
- Two shell bugs the original manual run hit, encoded here so they stay fixed: `awk -F. '{print $1"."$2"."$3}'` emits a trailing dot on two-component ids, and a zsh glob with no matches aborts the enclosing loop, which is why the script is bash and iterates `find` output files.
