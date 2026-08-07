#!/usr/bin/env python3
"""Map a target repository's agentic configuration surface and technology stack, and print it as JSON for the agent-digest skill."""

import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT_INSTRUCTIONS = ("AGENTS.md", "CLAUDE.md", "GEMINI.md", ".cursorrules", ".windsurfrules")
HARNESS_DIRS = {"claude": ".claude", "codex": ".codex", "copilot": ".copilot", "cursor": ".cursor", "shared": ".agents"}

INSTRUCTION_GLOBS = (
    ".agents/AGENTS.md",
    ".agents/rules/*.md",
    ".claude/CLAUDE.md",
    ".claude/rules/*.md",
    ".codex/AGENTS.md",
    ".copilot/copilot-instructions.md",
    ".copilot/instructions/*.md",
    ".cursor/rules/*.mdc",
    ".github/copilot-instructions.md",
    ".github/instructions/*.md",
)
SKILL_GLOBS = tuple(f"{d}/skills/*/SKILL.md" for d in (".agents", ".claude", ".codex", ".copilot"))
AGENT_GLOBS = tuple(f"{d}/agents/*" for d in (".agents", ".claude", ".codex"))
HOOK_GLOBS = (".agents/hooks/*", ".claude/hooks/*", ".codex/hooks.json")
COMMAND_GLOBS = (".claude/commands/**/*.md",)
# Harness directories also hold credentials, session caches, and private MCP definitions, so settings are allowlisted rather than globbed.
SETTINGS_GLOBS = (
    ".claude/settings.json",
    ".claude/statusline.json",
    ".codex/settings.toml",
    ".codex/hooks.json",
    ".copilot/settings.json",
    ".copilot/lsp-config.json",
    ".cursor/mcp.json",
    ".mcp.json",
    ".vscode/mcp.json",
)
SENSITIVE = re.compile(r"credential|secret|token|password|\.env|\.local\.|/config\.(json|toml)$")

LOCKFILES = {
    "pnpm-lock.yaml": "pnpm",
    "bun.lock": "bun",
    "bun.lockb": "bun",
    "yarn.lock": "yarn",
    "package-lock.json": "npm",
    "deno.lock": "deno",
}
MANIFESTS = (
    "package.json",
    "pyproject.toml",
    "requirements.txt",
    "Gemfile",
    "go.mod",
    "Cargo.toml",
    "composer.json",
    "Brewfile",
    "Dockerfile",
    "compose.yaml",
    "compose.yml",
    "docker-compose.yml",
)
RUNTIME_FILES = (".tool-versions", ".nvmrc", ".node-version", ".python-version", ".ruby-version", "mise.toml", ".mise.toml")
TOOL_CONFIG_GLOBS = ("*.config.js", "*.config.ts", "*.config.mjs", ".*rc", ".*rc.json", "*.json5", "biome.json", "tsconfig.json", ".rubocop.yml", ".shellcheckrc", ".editorconfig")

LIST_LIMIT = 60
FRONTMATTER_LIMIT = 4000
DESCRIPTION_LIMIT = 240


def resolve_root(given):
    if given:
        return Path(given).expanduser().resolve()
    try:
        output = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, timeout=10, check=True
        )
        return Path(output.stdout.strip()).resolve()
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
        return Path.cwd().resolve()


def collect(root, globs):
    """Return paths matching globs, deduplicated by real path so a symlinked route is not counted twice."""
    seen = {}
    for pattern in globs:
        for path in sorted(root.glob(pattern)):
            if SENSITIVE.search(path.as_posix()):
                continue
            real = path.resolve()
            entry = seen.setdefault(real, {"path": str(path.relative_to(root)), "aliases": []})
            if entry["path"] != str(path.relative_to(root)):
                entry["aliases"].append(str(path.relative_to(root)))
    return [{k: v for k, v in entry.items() if v} for entry in seen.values()]


def read_frontmatter(path):
    try:
        head = path.read_text(encoding="utf-8", errors="replace")[:FRONTMATTER_LIMIT]
    except OSError:
        return {}
    match = re.match(r"---\s*\n(.*?)\n---", head, re.DOTALL)
    if not match:
        return {}
    fields = {}
    for key in ("name", "description"):
        found = re.search(rf"^{key}:\s*(.+?)(?=\n[a-z_]+:|\Z)", match.group(1), re.MULTILINE | re.DOTALL)
        if found:
            fields[key] = re.sub(r"\s+", " ", found.group(1).strip().strip("\"'>|-")).strip()
    if "description" in fields:
        fields["description"] = fields["description"][:DESCRIPTION_LIMIT]
    return fields


def collect_skills(root):
    skills = []
    for entry in collect(root, SKILL_GLOBS):
        meta = read_frontmatter(root / entry["path"])
        skills.append({**entry, **meta})
    return skills


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def collect_stack(root):
    stack = {"package_manager": None, "runtimes": {}, "manifests": [], "dependencies": [], "tool_configs": [], "ci": []}

    for name, manager in LOCKFILES.items():
        if (root / name).exists():
            stack["package_manager"] = manager
            break

    package = read_json(root / "package.json")
    if package:
        if not stack["package_manager"] and isinstance(package.get("packageManager"), str):
            stack["package_manager"] = package["packageManager"].split("@")[0]
        stack["dependencies"] = sorted(
            set(package.get("dependencies", {})) | set(package.get("devDependencies", {}))
        )[:LIST_LIMIT]
        for engine, version in (package.get("engines") or {}).items():
            stack["runtimes"][engine] = version

    for name in RUNTIME_FILES:
        path = root / name
        if not path.exists():
            continue
        try:
            content = path.read_text(encoding="utf-8", errors="replace").strip()
        except OSError:
            continue
        stack["runtimes"][name] = content[:200]

    stack["manifests"] = [name for name in MANIFESTS if (root / name).exists()]
    stack["tool_configs"] = sorted({entry["path"] for entry in collect(root, TOOL_CONFIG_GLOBS)})[:LIST_LIMIT]
    stack["ci"] = sorted(
        {entry["path"] for entry in collect(root, (".github/workflows/*.yml", ".github/workflows/*.yaml"))}
    )[:LIST_LIMIT]
    return stack


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", help="repository to inventory (default: the git root of the working directory)")
    args = parser.parse_args()

    root = resolve_root(args.target)
    result = {
        "root": str(root),
        "name": root.name,
        "harnesses": sorted(key for key, directory in HARNESS_DIRS.items() if (root / directory).is_dir()),
        "instructions": collect(root, ROOT_INSTRUCTIONS + INSTRUCTION_GLOBS)[:LIST_LIMIT],
        "skills": collect_skills(root)[:LIST_LIMIT],
        "agents": collect(root, AGENT_GLOBS)[:LIST_LIMIT],
        "commands": collect(root, COMMAND_GLOBS)[:LIST_LIMIT],
        "hooks": collect(root, HOOK_GLOBS)[:LIST_LIMIT],
        "settings": collect(root, SETTINGS_GLOBS)[:LIST_LIMIT],
        "stack": collect_stack(root),
    }
    for key, name in (("feeds", "feeds.json"), ("config", "config.json")):
        path = root / ".agent-digest" / name
        result[key] = str(path.relative_to(root)) if path.exists() else None
    result["agentic"] = bool(result["instructions"] or result["skills"] or result["harnesses"])
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
