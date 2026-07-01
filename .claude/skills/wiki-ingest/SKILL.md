---
name: wiki-ingest
description: Ingest source material into the project LLM wiki. Use when adding notes, docs, research, issue context, or architecture knowledge to persistent memory.
argument-hint: "<source-path-or-topic>"
context: fork
agent: wiki-librarian
---

# Wiki Ingest

Source or topic: $ARGUMENTS

1. Read the source material.
2. Find existing related pages in `wiki/`.
3. Update existing pages first; create new pages only when needed.
4. Preserve source paths, dates, links, or citations.
5. Add cross-links from `wiki/INDEX.md`.
6. Flag contradictions or uncertainty explicitly.
7. Return a short changelog of wiki pages touched.

