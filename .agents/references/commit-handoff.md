# Commit handoff format

The rendering contract for the commit-handoff proposal required by `engineering.instructions.md`. Render the block itself, never a description of it, even when the prompt asks what you would do.

Render this block with the structure unchanged: fill the change list from the actual diff, one entry per change in the shape shown, and adapt only the proposal part, using Conventional Commits and inferring the appropriate type and optional scope from the changes:

````markdown
### Changes

- [file:line](path/to/file:line) - describes the resulting behavior.

I suggest creating a new commit:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

Want me to run it?
````

For an amend or squash, keep the change list and adapt only the proposal lines: name the target's short hash and subject, include the resulting message in the fenced block only when it changes, and end with the matching question ("Want me to run the squash?").

For a split, keep one `### Changes` block, divided by a `####` subheader per commit with a short imperative title ("Refactor chat header") and its own change list, and one closing question to end the block ("Want me to run both?"). When the changes span repositories, the subheaders name the repositories instead, and a repository with several commits nests its commit subheaders one level down.
