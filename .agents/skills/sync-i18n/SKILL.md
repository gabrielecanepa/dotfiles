---
name: sync-i18n
description: >-
  Audits and repairs a codebase's i18n catalogs, key usage, translations,
  loading, and configuration. Use for /sync-i18n or localization reviews;
  accepts a scope path and --check.
compatibility: Any coding agent with filesystem search, shell access, and official documentation lookup.
disable-model-invocation: true
---

# sync-i18n

Bring an existing internationalization setup to a verified, production-ready state without imposing a foreign pattern.

Detect the project's own framework and conventions first, then update messages, configuration, and architecture.

## Arguments and scope

- Parse an optional file or directory path and `--check` from the prompt.
- With no path, review the entire project; with a path, edit only that subtree.
- Read root manifests and i18n configuration to understand the scoped runtime, but report a required out-of-scope edit instead of applying it.
- Under `--check`, audit and report without editing, removing, installing, regenerating, or writing project files.
- In a narrow scope, keep root tooling read-only: no installs, lockfile updates, generated caches, or artifacts outside the requested subtree.
- Use existing tools in a non-mutating mode and report unavailable checks as blocked.

## Before changing files

1. Resolve the project root from version control; on failure, walk upward for project manifests and stop before the home directory.
2. Read the effective instruction chain.
3. Record `git status --short` and the relevant baseline checks.
4. Never stash, reset, or overwrite existing work.
5. State the resolved root, edit scope, and mode before changing files.

## Operating contract

- Detect the implementation from evidence; assume no JavaScript stack, catalog format, or framework convention.
- Treat the configured source or default locale as authoritative.
- When the source locale or intended meaning is ambiguous, apply only changes correct under either reading and surface the decision.
- Preserve placeholders, ICU arguments, plural and select branches, rich-text tags, escaping, and catalog data shapes.
- Remove a key only when repository-wide evidence proves it unused. Dynamic, generated, indirect, CMS-driven, and external keys survive a missed search.
- Keep edits recoverable and surgical. Never edit generated catalogs; update their source and regenerate through the project's existing tool.
- Never install or update dependencies unless the user explicitly asks, and report checks that cannot run.
- Do not add locales, rewrite product terminology, or change user-facing intent without evidence from the project or the user.

### Documentation lookup

- Consult current official documentation whenever a framework or library is in use, matched to the installed version.
- Prefer the `context7` MCP when available and official web documentation otherwise.
- When lookup is unavailable, continue with framework-neutral fixes and report the blocker.
- Never install a connector or dependency for documentation access, and never guess framework configuration or loading behavior.

## Phase 1: detect the setup

1. Search manifests, dependency locks, framework configuration, source imports, translation helpers, locale routing, extraction scripts, and message files.
2. Recognize packaged frameworks and custom implementations, including direct JSON, YAML, TypeScript, PO, MO, XLIFF, Fluent, or properties-file loading.
3. Accept one decisive signal or two corroborating signals.
4. Treat as decisive a configured i18n framework, a runtime translation API wired to catalogs, or a custom lookup helper with imported locale resources.
5. Never treat locale-looking files alone as enough; they may be fixtures or unrelated data.

### Record

- framework or custom pattern, with the installed version when available;
- source or default locale, supported locales, and fallback behavior;
- catalog locations and formats;
- runtime entry points, loaders, routing, middleware, and formatting helpers;
- extraction, validation, generation, and test commands.

When no setup is detected, make no edits and return this sentence and nothing else, with no blockquote or code fence:

No i18n setup was detected in `<scope>`. No files were changed.

## Phase 2: build the inventory

1. Read [references/review-rubric.md](references/review-rubric.md) before analysis.
2. Inventory every in-scope catalog, key, locale, call site, helper, configuration file, test, and i18n-related script.
3. Exclude vendored dependencies and build output, and trace generated resources back to their editable source.
4. Treat tests, stories, metadata, email templates, server code, route definitions, and build scripts as real consumers.
5. Expand computed keys to their finite family when the code makes that family knowable.

### Working maps

1. locale matrix: which keys and namespaces exist in each locale;
2. usage map: static use, bounded dynamic family, generated or indirect use, or proven unused;
3. message contract: placeholders, ICU branches, rich tags, and value types by locale;
4. loading map: which catalog or namespace reaches each route, feature, server boundary, and client bundle.

## Phase 3: evaluate and update

Under `--check`, perform the same analysis but express every mutation as a specific proposed update.

### General setup

- Compare the installed implementation with its current official documentation and the project's declared conventions.
- Check locale negotiation, supported and default locales, fallbacks, routing, and provider placement.
- Check server and client loading, formatters, error handling, type safety, catalog validation, and extraction.
- Apply documented, low-risk corrections, and do not migrate frameworks unless the user asked for a migration.

### Unused and inconsistent keys

- Remove every proven-unused key from every locale and editable source catalog, plus the empty namespace containers it leaves.
- Fix missing or extra locale entries, duplicate semantic keys, stale aliases, and catalog shape drift.
- Keep uncertain dynamic or external keys and explain why they could not be classified safely.

### Translation quality

- Establish the product voice, terminology, audience, and locale conventions from the source locale and nearby copy.
- Review every in-scope message, not only obvious spelling errors.
- Correct mistranslations, grammar, idiom, tone, punctuation, capitalization, pluralization, and formatting while preserving the message contract.
- Keep brand names and domain terms consistent, and never translate keys as a side effect of translating values.
- Expand every plural and select branch with representative values and read each rendered sentence on its own.
- Placeholder parity proves structural safety, not grammar or meaning, so a branch that parses can still need correction.
- A translation that reads better but breaks interpolation is a regression.

### Architecture and organization

- Review namespace ownership, catalog boundaries, import paths, key naming, and runtime loading as one system.
- Prefer stable semantic keys and namespaces owned by a feature, route, or domain.
- Use dynamic keys only for bounded, typed families the framework's extraction and validation tools can understand.
- Split catalogs when the framework can load the pieces independently and the split reduces shipped or parsed messages.
- Never split into request waterfalls or duplicated ownership, and merge fragments when separation adds indirection without a loading benefit.
- Update keys and call sites atomically.
- Follow the project's established naming convention unless official guidance or measured behavior justifies a change.

## Phase 4: verify and score

1. Run the project's own formatter and every applicable i18n extraction, compilation, validation, type, lint, test, and build check.
2. Verify directly that every editable catalog parses and that locale and namespace shapes match the intended source contract.
3. Verify that placeholders, ICU selectors, and rich tags match across locales.
4. Verify that no proven-unused or missing key remains and that changed keys resolve through every updated call site.
5. Verify that scoped loading still reaches the messages each route or feature needs.
6. Compare the final project state with the initial snapshot and remove verification artifacts this run created.
7. Fail the scope check when anything outside the edit boundary changed.

### Scoring

- Score the result with the ten checks in [references/review-rubric.md](references/review-rubric.md), then fix and rerun until all ten pass.
- Report 10/10 only when each point has evidence.
- When a blocker prevents a perfect result, report the achieved score and the specific blocker instead of rounding up.
- Blockers include a required out-of-scope change, a missing language decision, unavailable official documentation, and a failing external check.

## Final response

- Keep the response short, and return only the stop message when setup detection stopped the run.
- Otherwise output one sentence with the achieved score, then a table with two to five grouped rows.
- Include only rows that carry useful information, and mention unresolved decisions or blockers in the relevant cell.
- Under `--check`, label updates as proposed.
- Do not append a walkthrough or repeat the table in prose.

| Area         | Essential updates                             | Verification                         |
| ------------ | --------------------------------------------- | ------------------------------------ |
| Setup        | Framework, locales, and configuration changes | Official docs and relevant checks    |
| Messages     | Removed keys and translation corrections      | Catalog, parity, and contract checks |
| Architecture | Namespace, key, and loading changes           | Usage and loading evidence           |
| Final score  | `10/10` or the honest score with blocker      | Commands that passed                 |
