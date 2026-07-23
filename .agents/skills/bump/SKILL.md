---
name: bump
description: >-
  Upgrade a Node.js project to its latest toolchain and dependencies (Node LTS,
  package manager, every package) and keep the repo's checks green after code
  migration. Use for /bump or any request to update, upgrade, or bump
  dependencies, Node, or the package manager. Not for Python, Ruby, Rust, or Go.
---

# bump

Take a Node.js project from its current dependency state to fully current (Node
LTS, package manager, and all dependencies on their latest versions), with the
application code migrated to the new APIs and the repository's own checks
green at the end. Nothing here trusts a remembered version number: every
"latest" is resolved live at run time, because a skill that hardcodes versions
is wrong the day after it's written.

The bar to hold: when this finishes, the project is on current everything, the
code compiles and passes lint and tests, and the user has a clear table of what
changed and why, and was asked before any breaking change landed.

## Operating contract

Hold these for the whole run:

- **Resolve every version live.** Node LTS, package-manager versions, and
  dependency targets all come from a live query at run time (`nodejs.org`,
  `npm view`, `ncu`, the PM's own outdated command). Never write a version
  number from memory into a file or a decision.
- **Patch and minor are automatic; majors are the user's call.** Semver minor
  and patch bumps are safe by contract: apply them without asking. A major
  bump can break the build, so each one is a decision: present it with
  pros/cons and alternatives, and let the user choose.
- **Verify against the repo's own checks, not a feeling.** "It works" is not a
  result. Run the project's declared scripts (typecheck, lint, test, build) and
  loop until they pass. A passing typecheck is not a passing test suite.
- **Work in checkpoints so failure is recoverable.** Bump the toolchain, then
  patch/minor, verify and lock that in, _then_ take majors one at a time. If a
  major migration goes sideways you can abandon that one package without losing
  the rest of the work.
- **Migrate code from the source, not from guesswork.** When a major bump
  changes an API, read that package's actual changelog and release notes (via
  `context7` and the repo's own changelog) before touching code. Apply official
  codemods where they exist. Don't invent migrations.
- **Never commit or push.** Leave the working tree dirty so the user reviews the
  diff. Offer a Conventional Commit message at the end; the commit boundary is
  theirs.

## The optional prompt

`/bump <prompt>` may carry intent: fold it in. Examples: "just the patch and
minor stuff, skip majors" narrows scope; "we need to get off React 18" leads
with one target; "dev dependencies only" filters what you touch. With no
prompt, do the full upgrade. Always still run the repo's checks at the end
regardless of how narrow the prompt was.

## Phase 0: Confirm it's a Node project

Find the project root (`git rev-parse --show-toplevel`, falling back to walking
up for a `package.json`). If there is no `package.json`, stop: this skill is for
Node.js projects only. Say so plainly and don't proceed; bumping the wrong
ecosystem's dependencies is worse than doing nothing.

Read `package.json` once and note: declared `engines.node`, the `packageManager`
field if present, and whether this is a workspace/monorepo (a `workspaces` field
or `pnpm-workspace.yaml`). These shape every later phase.

## Phase 1: Toolchain, Node version and package manager

**Node version.** If the project pins a Node version (a `.node-version`,
`.nvmrc`, or `engines.node` in `package.json`), resolve the latest LTS live and
update the pin if it's behind:

```bash
curl -s https://nodejs.org/dist/index.json | \
  python3 -c "import sys,json; v=[x for x in json.load(sys.stdin) if x['lts']][0]; print(v['version'].lstrip('v'))"
```

Update only the files the project actually uses (don't create a `.nvmrc` if it
never had one). If the project pins no Node version at all, leave it; adding a
pin is a project decision, not an upgrade. Note the change for the report.

**Package manager.** Detect it from what the project declares, in priority
order:

1. `packageManager` field in `package.json` (e.g. `"pnpm@9.1.0"`), the
   tracked, authoritative choice.
2. A lockfile: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` →
   bun, `package-lock.json` → npm.
3. Nothing tracked → fall back to **npm**.

If the package manager is tracked via the `packageManager` field, upgrade it to
its latest version when it's behind. Resolve the latest live and pin it:

```bash
npm view <pm> dist-tags.latest   # e.g. npm view pnpm dist-tags.latest
```

Update the `packageManager` field to the resolved version (Corepack will honor
it). If the PM isn't tracked, don't introduce a pin; just use it to run the
upgrade.

Now load the command reference for the detected manager:
`references/package-managers.md` has the exact upgrade, outdated, and install
commands per manager (npm, pnpm, yarn, bun), including the monorepo flags. Read
the section for your detected PM before running anything.

## Phase 2: Survey what's outdated

Get the full outdated list with target versions, classified by semver bump
type. The cross-manager tool for this is `ncu` (npm-check-updates), which works
regardless of package manager and reports the jump type:

```bash
ncu                 # shows current → target for every dep, color-coded by semver
ncu --format group  # groups by patch / minor / major; use this to plan phases
```

For workspaces, add `--workspaces --root` (or run the PM's native outdated per
the reference). From this, build three buckets: **patch**, **minor**, **major**.
This classification drives the next two phases. Don't write anything yet; this
is the plan.

## Phase 3: Apply patch and minor, then verify

Apply every patch and minor bump. These are safe by semver contract, so they go
in without asking. Use the PM-appropriate command from the reference (e.g.
`ncu -u --target minor && <pm> install`, or `pnpm update`).

Then **verify the repo is still green** before going further: run the project's
declared checks (see Phase 5 for how to find them). If patch/minor broke
something (it happens, semver is a promise not a guarantee), fix it now while
the cause is isolated to a small, safe set of bumps. Lock in this known-good
state before touching any major.

## Phase 4: Majors, one at a time

For each major bump, this is a decision the user owns. Don't batch them blind
and don't take them silently. For each one:

1. **Research the jump.** Read the package's changelog and release notes for
   what actually breaks between the installed and target major. Use `context7`
   for the library's current docs and the package's own `CHANGELOG`/releases.
   Note whether an official codemod exists (many big libraries ship one).
2. **Present the decision** with selectable options via the host's question
   mechanism: the bump (`pkg 4.2.1 → 5.0.0`), the concrete breaking changes that
   touch _this_ repo, the pros (security, features, support window) and cons
   (migration effort, risk), and **alternatives**: most importantly, staying on
   the current major (bump to its latest patch instead) when the major isn't
   worth it yet. Give a recommended default.
3. **On approval, migrate from the source.** Apply the bump, run the official
   codemod if one exists, then make the code changes the changelog calls for;
   read the actual release notes, don't guess at the new API. Install.
4. **Verify before the next major.** Run the repo's checks. Loop until green:
   fix the migration, not the symptom. Only when this major is green do you move
   to the next one. This keeps each major's risk contained.

If a migration turns out to be genuinely ambiguous (the changelog is unclear,
two valid code paths exist), stop and ask rather than guessing; surface the
ambiguity with the options you see.

## Phase 5: Final verification

Install cleanly and confirm **no errors and no warnings** from the install
itself (peer-dependency conflicts, deprecation warnings that matter). Then run
the project's own checks; detect them from `package.json` `scripts`, don't
assume names. Run what exists, in this order, fixing failures your changes
caused:

1. **Typecheck**: `tsc --noEmit`, or the project's `typecheck`/`check` script.
2. **Lint**: the project's `lint` script.
3. **Test**: the project's `test` script (the real signal that nothing
   regressed).
4. **Build**: the project's `build` script, if it has one.

Use the project's package manager to run these (`<pm> run <script>`). If a check
fails because of a bump, that's in scope: fix it. If it was already failing
before you started (check by stashing or reasoning about it), say so rather than
chasing a pre-existing failure.

## Phase 6: Report

Output a single well-formatted table of everything that changed, then a short
prose summary. The table is the deliverable; make it scannable:

| Package      | From   | To     | Type  | Notes                                                       |
| ------------ | ------ | ------ | ----- | ----------------------------------------------------------- |
| `react`      | 18.3.1 | 19.1.0 | major | New JSX transform; updated `use` hook calls in `src/hooks/` |
| `vite`       | 5.4.2  | 5.4.8  | patch |                                                             |
| `typescript` | 5.4.5  | 5.6.3  | minor |                                                             |

Include the toolchain rows too (Node, package manager) at the top. The **Type**
column is the semver jump (patch/minor/major); **Notes** is a brief, concrete
description of any code that changed and why, empty for clean patch/minor
bumps. Group or sort so majors (the rows that carried risk) are easy to find.

After the table:

- **Code changes**: a short list of files touched for API migrations, one line
  each, only if any code changed.
- **Checks**: which checks ran and their result (e.g. "typecheck ✓, lint ✓,
  test ✓ 142 passing, build ✓").
- **Skipped** _(if any)_: majors the user declined and what they're still on.
- **Commit**: offer a Conventional Commit message (e.g.
  `chore(deps): upgrade dependencies to latest`) but do not commit. Leave the
  tree dirty for review.

Keep it honest: if a check failed and you couldn't resolve it, say so with the
error; don't claim green when it isn't.

## Bundled resources

- `references/package-managers.md`: exact upgrade, outdated, and install
  commands per package manager (npm, pnpm, yarn, bun), including monorepo flags
  and how each pins its own version. Read the section for the detected manager.
