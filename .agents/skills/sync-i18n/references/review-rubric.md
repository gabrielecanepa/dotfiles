# i18n review rubric

Use this rubric after detecting the project's implementation. Framework documentation and repository evidence outrank generic advice.

## Contents

- [Detection evidence](#detection-evidence)
- [Safe usage classification](#safe-usage-classification)
- [Message review](#message-review)
- [Architecture review](#architecture-review)
- [Official documentation check](#official-documentation-check)
- [Ten-point score](#ten-point-score)

## Detection evidence

Look across the whole stack. Common evidence includes:

- JavaScript and TypeScript: `next-intl`, `i18next`, `react-i18next`, FormatJS or `react-intl`, Lingui, Vue I18n, Angular localize, Svelte i18n, framework locale routing, and direct catalog imports;
- Python: gettext, Babel or Flask-Babel, Django translation APIs, PO catalogs, and extraction or compilation commands;
- Ruby: Rails I18n configuration, YAML locale trees, and `I18n.t` call sites;
- JVM and Android: resource bundles, properties files, Android string resources, ICU/MessageFormat use, and locale qualifiers;
- Apple platforms: string catalogs, `.strings`, `.stringsdict`, and localized resource lookup;
- custom systems: locale registries, lookup helpers, imported JSON/YAML/TS objects, database-backed catalogs, or build-time message generation.

Dependency presence is supporting evidence, not proof of use. Catalogs named `en.json` or `translations.yml` are also insufficient without a runtime, build-time, or generation path that consumes them.

## Safe usage classification

Classify a key as proven unused only after checking:

- literal calls, aliases, wrappers, and re-exports;
- template syntax, server-rendered views, emails, metadata, tests, and stories;
- computed keys and finite families such as `status.${state}`;
- framework extraction configuration and generated key manifests;
- external contracts documented in code, schemas, APIs, CMS integrations, or translation-platform sync jobs.

If a family cannot be enumerated, keep it. Record the uncertainty as an architecture finding and prefer making the family explicit or typed when that fits the project.

## Message review

For each locale and message:

- compare meaning with the source locale and surrounding product flow;
- preserve variable names, plural/select categories, rich tags, markup, escape rules, newlines, and value types;
- use the target locale's grammar, idiom, punctuation, casing, number/date conventions, and level of formality;
- keep shared terminology and calls to action consistent across features;
- distinguish missing translations from deliberate locale-specific omissions;
- reject fluent-sounding text that changes product behavior or weakens a legal, financial, privacy, or safety statement.

Do not infer expertise you do not have. When a correction depends on native language judgment that repository evidence cannot settle, surface it for review.

## Architecture review

Judge organization by ownership and runtime behavior, not catalog size alone.

- Give each namespace one clear feature, route, or domain owner.
- Keep shared messages genuinely shared; a generic `common` namespace should not become a dumping ground.
- Prefer stable semantic keys. Follow an existing, coherent convention before introducing a new one.
- Avoid building full sentences from translated fragments. Grammar and word order vary by locale.
- Bound dynamic keys so static validation, extraction, and type checking can see the complete family.
- Load only what the runtime needs when the framework supports safe selective loading. Prove the bundle, parse, or request benefit before adding boundaries.
- Keep server-only catalogs off client bundles where the framework supports that distinction.
- Centralize locale registries, fallback rules, and formatter defaults so routing and rendering cannot drift.
- Validate catalogs in automation with the framework's supported tools before adding custom scripts.

## Official documentation check

Determine the installed framework version from the lockfile or manifest. Read current official documentation for configuration, message syntax, extraction, type safety, routing, and loading behavior relevant to the finding. Prefer an installed documentation connector such as `context7-mcp`; otherwise browse the framework's official site. Record the page or section that governed each non-obvious architecture or configuration change.

If official documentation is unavailable, continue only with framework-neutral message corrections that repository evidence proves safe. Treat undocumented configuration or loading changes as blocked.

## Ten-point score

Award one point only when the condition passes with current evidence:

1. The framework or custom runtime, version, catalogs, and editable sources are correctly identified.
2. Supported, source/default, and fallback locales form one consistent contract.
3. Every catalog parses or compiles and matches its intended schema.
4. Locale coverage is complete, with no proven-unused, missing, or accidental extra keys.
5. Placeholders, ICU branches, rich tags, and value types match across locales.
6. Reviewed translations preserve meaning and follow target-locale language and project terminology.
7. Keys and namespaces have consistent names, clear ownership, and safe dynamic families.
8. Routing, providers, imports, and fallback/error behavior follow installed framework guidance or a coherent custom contract.
9. Catalog loading respects server/client and route or feature boundaries without avoidable payload or request cost.
10. Relevant extraction, validation, format, type, lint, test, and build checks pass, or the project has equivalent automated coverage for every changed surface.

Not applicable is not an automatic point. Show why the condition does not apply and provide equivalent evidence for the risk it represents.
