---
name: bump
description: >-
  Upgrades a Node.js project's Node LTS pin, package manager, and dependencies,
  migrating code as needed. Use for /bump or dependency upgrade requests; not
  for Python, Ruby, Rust, or Go.
disable-model-invocation: true
---

# bump

Take a Node.js project to current Node LTS, package manager, and dependencies, with the code migrated to the new APIs and the repository's own checks green.

## Operating contract

- Resolve every version live from `nodejs.org`, `npm view`, `ncu`, or the manager's outdated command. Never write a version number from memory.
- Apply patch and minor bumps without asking; they are safe by semver contract.
- Treat every major as the user's decision: present pros, cons, and alternatives, then let the user choose.
- Verify against the repository's declared scripts, never a feeling. A passing typecheck is not a passing test suite.
- Work in checkpoints: toolchain, then patch and minor verified, then majors one at a time, so a failed migration loses only that package.
- Migrate code from the package's changelog and release notes, and apply official codemods. Never invent a migration.
- Never commit or push. Leave the working tree dirty and offer a Conventional Commit message at the end.

## Arguments

- With no prompt, `/bump` does the full upgrade.
- `/bump <prompt>` carries intent, so fold it in: "just the patch and minor stuff, skip majors" narrows scope.
- "we need to get off React 18" leads with that one target; "dev dependencies only" filters what you touch.
- Run the repository's checks at the end regardless of how narrow the prompt was.

## Phase 0: confirm a Node project

1. Find the project root with `git rev-parse --show-toplevel`, falling back to walking up for a `package.json`.
2. When there is no `package.json`, stop and say so plainly: this skill is for Node.js projects only.
3. Read `package.json` once and note `engines.node`, `packageManager`, and whether `workspaces` or `pnpm-workspace.yaml` makes this a monorepo.

## Phase 1: toolchain, Node, and package manager

1. When the project pins Node in `.node-version`, `.nvmrc`, or `engines.node`, resolve the latest LTS live and update the pin if it is behind.

```bash
curl -s https://nodejs.org/dist/index.json | \
  python3 -c "import sys,json; v=[x for x in json.load(sys.stdin) if x['lts']][0]; print(v['version'].lstrip('v'))"
```

2. Update only the pin files the project already uses, never creating a `.nvmrc` it never had. Note the change for the report.
3. When the project pins no Node version, leave it: adding a pin is a project decision, not an upgrade.
4. Detect the package manager in priority order: the `packageManager` field, then the lockfile, then npm as the fallback.
5. Map lockfiles: `pnpm-lock.yaml` to pnpm, `yarn.lock` to yarn, `bun.lockb` to bun, `package-lock.json` to npm.
6. When `packageManager` is present and behind, resolve the latest with `npm view <pm> dist-tags.latest` and pin it so Corepack honors it.
7. When the manager is untracked, introduce no pin; just use it to run the upgrade.
8. Read the detected manager's section in [references/package-managers.md](references/package-managers.md) before running anything.

## Phase 2: survey what is outdated

1. Run `ncu` for the full outdated list with target versions, classified by semver bump type; it works with any manager.
2. For workspaces, add `--workspaces --root`, or run the manager's native outdated command from the reference.
3. Build three buckets, patch, minor, and major, to drive the next two phases. Write nothing yet; this is the plan.

```bash
ncu                 # current and target version for every dep
ncu --format group  # groups by patch / minor / major; use this to plan phases
```

## Phase 3: apply patch and minor, then verify

1. Apply every patch and minor bump with the reference's command for the detected manager, such as `ncu -u --target minor && <pm> install`.
2. Always follow an `ncu -u` with the manager's own install so the lockfile and `node_modules` match `package.json`.
3. Run the project's declared checks from phase 5 before going further.
4. When a patch or minor bump broke something, fix it now while the cause is isolated to a small, safe set of bumps.
5. Lock in this known-good state before touching any major.

## Phase 4: majors, one at a time

1. Research the jump: read the package's changelog and release notes for what breaks between the installed and target major, using `context7`.
2. Note whether an official codemod exists; many large libraries ship one.
3. Present the decision with selectable options through the host's question mechanism, and give a recommended default.
4. State the bump (`pkg 4.2.1` to `5.0.0`), the breaking changes touching this repo, the pros (security, features, support), and the cons (effort, risk).
5. Offer alternatives, above all staying on the current major and bumping to its latest patch when the major is not worth it yet.
6. On approval, apply the bump, run the codemod if one exists, make the changes the release notes call for, then install.
7. Run the repository's checks and loop until green, fixing the migration rather than the symptom, before starting the next major.
8. When a migration is genuinely ambiguous, stop and ask with the options you see rather than guessing.

## Phase 5: final verification

1. Install cleanly and confirm no errors and no warnings from the install itself, peer-dependency conflicts and deprecations included.
2. Detect the checks from `package.json` `scripts`, never assuming script names, and run each with `<pm> run <script>`.
3. Typecheck with `tsc --noEmit` or the project's `typecheck` or `check` script.
4. Lint with the project's `lint` script.
5. Test with the project's `test` script, the real signal that nothing regressed.
6. Build with the project's `build` script when it has one.
7. When a check fails because of a bump, fix it: that is in scope.
8. When a check was already failing before the run, say so rather than chasing a pre-existing failure.

## Phase 6: report

Output one table of everything that changed, then short notes. The table is the deliverable, so make it scannable.

| Package      | From   | To     | Type  | Notes                                                       |
| ------------ | ------ | ------ | ----- | ----------------------------------------------------------- |
| `react`      | 18.3.1 | 19.1.0 | major | New JSX transform; updated `use` hook calls in `src/hooks/` |
| `vite`       | 5.4.2  | 5.4.8  | patch |                                                             |
| `typescript` | 5.4.5  | 5.6.3  | minor |                                                             |

- Put the toolchain rows, Node and package manager, at the top, and sort or group so the majors are easy to find.
- Set `Type` to the semver jump, and `Notes` to what code changed and why, left empty for clean patch and minor bumps.
- Code changes: one line per file touched for an API migration, only when code changed.
- Checks: which checks ran and their result, such as `typecheck pass, lint pass, test pass 142 passing, build pass`.
- Skipped: the majors the user declined and the versions they are still on, when there are any.
- Commit: offer a Conventional Commit message such as `chore(deps): upgrade dependencies to latest`, but never commit.
- When a check failed and you could not resolve it, report it with the error; never claim green when it is not.

## Bundled resources

- [references/package-managers.md](references/package-managers.md): outdated, upgrade, and install commands per manager, plus monorepo flags.
