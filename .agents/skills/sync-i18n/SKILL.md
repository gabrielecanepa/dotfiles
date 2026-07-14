---
name: sync-i18n
description: >-
  Audits and repairs a codebase's i18n setup: catalogs, key usage, translations,
  loading, and framework configuration. Use for `/sync-i18n` or requests to
  review, sync, clean, or improve project localization; accepts a scope path and
  `--check`.
compatibility: Any coding agent with filesystem search, shell access, and official documentation lookup.
---

# sync-i18n

Bring an existing internationalization setup to a verified, production-ready
state. Detect the project's own framework and conventions first, then update
messages, configuration, and architecture without imposing a foreign pattern.

## Arguments and scope

Parse an optional file or directory path and `--check` from the prompt. With no
path, review the entire project. With a path, edit only that subtree. You may
read root manifests and i18n configuration to understand the scoped runtime,
but report a required out-of-scope edit instead of applying it. Under `--check`,
audit and report without editing, removing, installing, regenerating, or writing
project files.

In a narrow scope, root tooling is read-only: do not install dependencies,
update lockfiles, generate caches, or leave artifacts outside the requested
subtree. Use existing tools in a non-mutating mode and report unavailable checks
as blocked.

Resolve the project root from version control first. If that fails, walk upward
from the current directory for project manifests and stop before the home
directory. Read the effective instruction chain, then record `git status --short`
and relevant baseline checks. Never stash, reset, or overwrite existing work.
State the resolved root, edit scope, and mode before changing files.

## Operating contract

- Detect the implementation from evidence. Do not assume a JavaScript stack, a
  particular catalog format, or one framework's conventions.
- Treat the configured source or default locale as authoritative. If the source
  locale or intended meaning is ambiguous, apply only changes that remain
  correct under either interpretation and surface the decision.
- Preserve placeholders, ICU arguments, plural/select branches, rich-text tags,
  escaping, and catalog data shapes. A translation that reads better but breaks
  interpolation is a regression.
- Consult current official documentation whenever a framework or library is in
  use. Use the available documentation lookup capability, preferring
  `context7-mcp` when installed and official web documentation otherwise.
  Match documentation to the installed version. If lookup is unavailable,
  continue with framework-neutral fixes and report the blocker. Do not install
  a connector or dependency solely for documentation access, and do not guess
  at framework configuration or loading behavior.
- Remove a key only when repository-wide evidence proves it unused. Dynamic,
  generated, indirect, CMS-driven, or externally consumed keys are not unused
  merely because a literal search misses them.
- Keep edits recoverable and surgical. Never edit generated catalogs directly;
  update their source and regenerate them through the project's existing tool.
- Never install or update dependencies unless the user explicitly asks. Use
  already-installed tools and report checks that cannot run.
- Do not add locales, rewrite product terminology, or change user-facing intent
  without evidence from the project or the user.

## Phase 1: detect the setup

Search manifests, dependency locks, framework configuration, source imports,
translation helpers, locale routing, extraction scripts, and message files.
Recognize both packaged frameworks and custom implementations, including direct
JSON, YAML, TypeScript, PO, MO, XLIFF, Fluent, or properties-file loading.

Use one decisive signal or two corroborating signals. Decisive signals include
a configured i18n framework, a runtime translation API wired to catalogs, or a
custom lookup helper with imported locale resources. Locale-looking files alone
are not enough because they may be fixtures or unrelated data.

Record:

- framework or custom pattern and installed version when available;
- source/default locale, supported locales, and fallback behavior;
- catalog locations and formats;
- runtime entry points, loaders, routing, middleware, and formatting helpers;
- extraction, validation, generation, and test commands.

If no setup is detected, make no edits and return this sentence and nothing
else. Do not prefix it with a blockquote or code fence.

No i18n setup was detected in `<scope>`. No files were changed.

## Phase 2: build the inventory

Read [references/review-rubric.md](references/review-rubric.md) before analysis.
Inventory every in-scope catalog, key, locale, call site, helper, configuration
file, test, and i18n-related script. Exclude vendored dependencies and build
output. Trace generated resources back to their editable source.

Build these working maps:

1. locale matrix: which keys and namespaces exist in each locale;
2. usage map: static use, bounded dynamic family, generated/indirect use, or
   proven unused;
3. message contract: placeholders, ICU branches, rich tags, and value types by
   locale;
4. loading map: which catalog or namespace reaches each route, feature, server
   boundary, and client bundle.

Treat tests, stories, metadata, email templates, server code, route definitions,
and build scripts as real consumers. Expand computed keys to their finite family
when the code makes that family knowable.

## Phase 3: evaluate and update

Under `--check`, perform the same analysis but express every mutation as a
specific proposed update.

### General setup

Compare the installed implementation with its current official documentation
and the project's declared conventions. Check locale negotiation, supported and
default locales, fallbacks, routing, provider placement, server/client loading,
formatters, error handling, type safety, catalog validation, and extraction.
Apply documented, low-risk corrections. Do not migrate frameworks unless the
user asked for a migration.

### Unused and inconsistent keys

Remove every proven-unused key from every locale and editable source catalog.
Remove empty namespace containers left by that deletion. Fix missing or extra
locale entries, duplicate semantic keys, stale aliases, and catalog shape
drift. Keep uncertain dynamic or external keys and explain why they could not be
classified safely.

### Translation quality

Establish the product voice, terminology, audience, and locale conventions from
the source locale and nearby copy. Review every in-scope message, not only
obvious spelling errors. Correct mistranslations, grammar, idiom, tone,
punctuation, capitalization, pluralization, and formatting while preserving the
message contract. Keep brand names and domain terms consistent. Do not translate
keys as a side effect of translating values.

Expand every plural and select branch with representative values and read each
rendered sentence on its own. Placeholder parity proves structural safety, not
grammar or meaning, so a branch that parses can still need correction.

### Architecture and organization

Review namespace ownership, catalog boundaries, import paths, key naming, and
runtime loading as one system. Prefer stable semantic keys and namespaces owned
by a feature, route, or domain. Use dynamic keys only for bounded, typed families
that the framework's extraction and validation tools can understand.

Split catalogs when the framework can load the pieces independently and the
change reduces shipped or parsed messages without creating request waterfalls
or duplicated ownership. Merge fragments when separation adds indirection
without a loading benefit. Update keys and call sites atomically, and follow the
project's established naming convention unless official guidance or measured
behavior justifies a change.

## Phase 4: verify and score

Run the project's own formatter and all applicable i18n extraction, compilation,
validation, type, lint, test, and build checks. Also verify directly that:

- every editable catalog parses;
- locale and namespace shapes match the intended source contract;
- placeholders, ICU selectors, and rich tags match across locales;
- no proven-unused or missing key remains;
- changed keys resolve through every updated call site;
- scoped loading still reaches the messages each route or feature needs.

Compare final project state with the initial snapshot. Remove verification
artifacts created by this run and fail the scope check if anything outside the
edit boundary changed.

Score the result with the ten checks in the rubric. Fix and rerun until all ten
pass. Report 10/10 only when each point has evidence. If an out-of-scope change,
missing language decision, unavailable official documentation, or failing
external check prevents a perfect result, report the achieved score and the
specific blocker instead of rounding up.

## Final response

Keep the response short. If setup detection stopped the run, return only the
required stop message. Otherwise output one sentence with the achieved score,
then a table with two to five grouped rows:

| Area         | Essential updates                             | Verification                         |
| ------------ | --------------------------------------------- | ------------------------------------ |
| Setup        | Framework, locales, and configuration changes | Official docs and relevant checks    |
| Messages     | Removed keys and translation corrections      | Catalog, parity, and contract checks |
| Architecture | Namespace, key, and loading changes           | Usage and loading evidence           |
| Final score  | `10/10` or the honest score with blocker      | Commands that passed                 |

Include only rows that carry useful information. Mention unresolved decisions
or blockers in the relevant cell. Under `--check`, label updates as proposed.
Do not append a walkthrough or repeat the table in prose.
