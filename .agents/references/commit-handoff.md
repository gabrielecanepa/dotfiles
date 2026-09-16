# Commit handoff format

The rendering contract for the commit-handoff proposal required by `engineering.md`.

Choose between a new commit, an amend or squash, and a split per the "Commit decision" section of `verification.md`.

Render the block itself, never a description of it, even when the prompt asks what you would do.

Render this block with the structure unchanged. Fill the change list from the actual diff, one entry per change in the shape shown.

Adapt only the proposal part, using Conventional Commits and inferring the type and optional scope from the changes:

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

Write the whole message unwrapped. Hard-wrap only when the repository declares a convention or sets commitlint's `body-max-line-length`.

Include a body only when the subject cannot explain the full intent.

Write the body as imperative prose that explains why the change was made and how behavior differs.

Switch to bullets only for independent enumerable changes: hyphen, single space, short imperative fragments, no terminal period.

Never end the subject with a period.

For an amend or squash, keep the change list and adapt only the proposal lines.

Name the target's short hash and subject, include the resulting message only when it changes, and end with the matching question.

For a split, keep one `### Changes` block divided by a `####` subheader per commit, each with a short imperative title and its own change list.

Close a split with one question covering every commit.

When the changes span repositories, the subheaders name the repositories, and a repository with several commits nests its commit subheaders one level down.
