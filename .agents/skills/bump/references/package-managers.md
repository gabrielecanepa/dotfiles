# Package manager command reference

Exact commands per manager for the three operations bump needs: **survey
outdated**, **apply upgrades** (split by semver target), and **install**. Read
only the section for the manager you detected in Phase 1.

`ncu` (npm-check-updates) is the cross-manager workhorse for surveying and
selectively upgrading: it edits `package.json` version ranges and works with
any manager. After `ncu -u` you always run the manager's own `install` to update
the lockfile. The manager-native commands below are the alternative when you'd
rather not depend on `ncu`.

A note on "latest" vs ranges: `<pm> update` respects the semver ranges already
in `package.json` (so `^5.2.0` won't cross to `6.x`). To cross majors you must
rewrite the range; that's what `ncu -u` does, or the manager's explicit
"latest" flag where it has one. bump deliberately separates patch/minor (range-
respecting, safe) from majors (range-rewriting, gated by user approval), so the
two paths below matter.

## Resolving "latest" live

- **Latest LTS Node:**
  ```bash
  curl -s https://nodejs.org/dist/index.json | \
    python3 -c "import sys,json; v=[x for x in json.load(sys.stdin) if x['lts']][0]; print(v['version'].lstrip('v'))"
  ```
- **Latest version of any npm package** (including a package manager):
  ```bash
  npm view <name> dist-tags.latest
  ```
- **Latest of a specific major line** (when a user wants to stay on a major):
  ```bash
  npm view <name> dist-tags   # lists latest-1, latest-2, … per major where published
  npm view <name> versions --json   # full list to pick the highest of a major
  ```

## ncu: cross-manager survey and upgrade

```bash
ncu                          # report: current → latest target for every dep
ncu --format group           # grouped by patch / minor / major (use to plan)
ncu --target minor           # report only what's a minor-or-lower bump
ncu -u --target patch        # write patch bumps into package.json
ncu -u --target minor        # write patch+minor bumps into package.json
ncu -u --filter <pkg>        # write just one package (used per-major in Phase 4)
ncu -u                       # write ALL to latest, including majors (avoid blanket use)
```

Monorepo / workspaces: add `--workspaces --root` to cover every workspace plus
the root, or `--deep` to recurse into all `package.json` files found.

`--peer` makes ncu respect peer-dependency constraints when picking targets,
useful to avoid proposing a bump that immediately breaks peers.

Always follow an `ncu -u` with the manager's install (next sections) to sync the
lockfile and `node_modules`.

## npm

```bash
npm outdated                 # native outdated report (current / wanted / latest)
npm update                   # bump within existing ranges (patch/minor), update lock
npm install                  # install from package.json, refresh lock + node_modules
npm install <pkg>@latest     # cross a major for one package explicitly
npm ci                       # clean install strictly from lock (use to verify lock is valid)
```

npm has no built-in "upgrade everything across majors"; use `ncu -u` then
`npm install`. `npm outdated` exits non-zero when anything is outdated; that's
informational, not an error.

Workspaces: `npm update --workspaces`, `npm install --workspaces`.

## pnpm

```bash
pnpm outdated                # outdated report
pnpm update                  # bump within ranges (patch/minor), update lock
pnpm update --latest         # cross majors: update to latest ignoring ranges (== ncu -u + install)
pnpm update -L               # short form of --latest
pnpm update <pkg> --latest   # one package to latest across majors
pnpm install                 # install from manifest, refresh lock + node_modules
```

`pnpm update --latest` (or `-L`) is the native equivalent of `ncu -u && install`
in one step, but it crosses majors, so only use it once majors are approved, or
scope it to specific packages. For the safe patch/minor pass, plain
`pnpm update` is correct.

Monorepo: add `-r` / `--recursive` to run across all workspace packages
(`pnpm -r update`).

## yarn

Commands differ by yarn major. Detect with `yarn --version`.

**Yarn Classic (1.x):**

```bash
yarn outdated
yarn upgrade                 # within ranges
yarn upgrade <pkg>@latest    # one package across a major
yarn install                 # install from lock
```

**Yarn Berry (2+):**

```bash
yarn upgrade-interactive     # interactive picker (not usable headless; prefer ncu)
yarn up <pkg>                # upgrade a package (Berry syntax)
yarn up '*'                  # upgrade all to latest within ranges
yarn install
```

For Berry, `ncu -u` + `yarn install` is the most reliable non-interactive path
since `upgrade-interactive` needs a TTY.

## bun

```bash
bun outdated                 # outdated report
bun update                   # bump within ranges (patch/minor)
bun update --latest          # cross majors to latest (== ncu -u + install)
bun update <pkg> --latest    # one package to latest
bun install                  # install from bun.lockb
```

`bun update --latest` crosses majors like pnpm's; gate it behind major
approval or scope it per-package. Plain `bun update` is the safe patch/minor
pass.

## After upgrading: verifying a clean install

Whatever manager, the final install must be clean. Watch the install output for:

- **peer dependency conflicts**: npm prints `ERESOLVE`; pnpm and others warn.
  A bump that forces `--force`/`--legacy-peer-deps` to install is a red flag,
  not a fix. Surface it as a decision.
- **deprecation warnings** for a package you just bumped (the new version may
  deprecate something you rely on).
- **lockfile churn** that doesn't match what you intended; re-run the survey to
  confirm the resulting versions are what you approved.
