# Doc inventory

The in-scope and out-of-scope file map for sync-docs, plus each doc's role. Loaded in Phase 1.

## In scope

- Community-health docs: `README*`, `CONTRIBUTING*`, `CHANGELOG*`, `CODE_OF_CONDUCT*`, `SECURITY*`, `SUPPORT*`, `GOVERNANCE*`, `FUNDING*`, `AUTHORS*`.
- More root docs: `INSTALL*`, `USAGE*`, `FAQ*`.
- Any other `*.md`, `*.rst`, or `*.txt` at the repo root clearly written for a person.

### Docs trees and sites

- `docs/` and `doc/` trees: guides, tutorials, references, how-tos, in Markdown, reStructuredText, MDX, or AsciiDoc.
- Site sources: `website/`, `site/`, and docs-generator content (Docusaurus, MkDocs, Sphinx, VitePress, Astro Starlight, Jekyll `_docs`).
- In site sources, audit the prose, not the generator config.
- Nav and index config that lists pages (`sidebars.js`, an MkDocs `nav:` block, a Sphinx `toctree`), as a link-integrity target only.
- `.github/` human templates: `ISSUE_TEMPLATE/*`, `PULL_REQUEST_TEMPLATE*`, `DISCUSSION_TEMPLATE/*`.
- In-repo package docs: a `README` inside each published package of a monorepo, where the nearest README wins and holds only what is specific to that package.

## GitHub resolution

- GitHub resolves README, CONTRIBUTING, SECURITY, SUPPORT, CODE_OF_CONDUCT, GOVERNANCE, and FUNDING from `.github/`, then the root, then `docs/`.
- It renders the first copy it finds.
- Always inventory `.github/` for these files, because a repo whose front page is `.github/README.md` has no root README at all.
- Treat whichever copy GitHub would render as the canonical one.
- Never read `.github/` as agent config; the agent files that live there are excluded by name below.

## Out of scope, never edit

- Agentic docs: `AGENTS.md` and nested copies, `CLAUDE.md`, `.cursor/`, `.cursorrules`, `GEMINI.md`, `.windsurfrules`, `.clinerules`, `.aider*`.
- More agentic docs: `.github/copilot-instructions.md`, `.github/instructions/*`, the `.agents/` and `.claude/` trees, any `SKILL.md`, rule files, MCP config.
- When a task spans both surfaces, do the human docs here and hand the agentic side to `sync-agents`.
- Generated docs: API reference emitted by `typedoc`, `jsdoc`, `sphinx-apidoc`, or `cargo doc`, and `CHANGELOG` entries produced by a release tool.
- When a generated doc is stale, flag it as a regenerate follow-up instead of editing it.
- Build output: anything under `node_modules/`, `dist/`, `_site/`, a `site/` build, or `target/doc/`.
- `LICENSE` and `COPYING`: verify the file exists and the README's stated license matches it, but never rewrite the wording; a mismatch is a decision to flag.
- Machine-authored data the docs embed by include or transclusion: fix it at its source, not in the rendered copy.

## Manifest fields

- Record each file's path and role from the lists above.
- When the repo declares a doc length or line-width cap, record it as a checkable convention.
