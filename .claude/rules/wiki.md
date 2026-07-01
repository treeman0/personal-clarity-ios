# Wiki Rules

- `wiki/` is persistent project knowledge, not a scratchpad.
- Raw source material belongs in `wiki/sources/` or stays outside the repo; compiled knowledge belongs in topic pages.
- Preserve citations or source paths when ingesting information.
- When new information contradicts an existing page, update the page and note the contradiction instead of silently overwriting history.
- Keep pages short enough to scan. Split concepts, decisions, and procedures into separate files.
- Link related pages with relative markdown links.
- Treat wiki review as part of done. After non-wiki edits, decide whether the work created durable knowledge.
- Update `wiki/` when you discover architecture decisions, domain facts, setup quirks, recurring failures, migration results, external integration details, or project-specific test commands.
- If no wiki update is useful, write `.claude/state/wiki-review-waiver.md` with a one-sentence reason.
- Do not put transient task notes, raw logs, or secrets in `wiki/`.
