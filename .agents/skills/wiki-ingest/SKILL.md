---
name: wiki-ingest
description: Use when Codex needs to preserve durable project knowledge, migration notes, decisions, setup quirks, recurring failures, or source material in the project wiki.
---

# Wiki Ingest

Read `.claude-loop.json`. If `loop.wikiMemory` is false, do not add wiki pages unless explicitly requested.

1. Decide whether the information will matter after the current task.
2. Put raw source material in `wiki/sources/` when it should be preserved.
3. Put synthesized knowledge in `wiki/concepts/`, `wiki/decisions/`, or another focused wiki page.
4. Preserve source paths, dates, or links when relevant.
5. Keep pages short and link related pages with relative Markdown links.
6. Do not store secrets, transient logs, or scratch notes in `wiki/`.

If `loop.wikiGate` is true and no wiki update is useful after a meaningful change, say why in the final response.
