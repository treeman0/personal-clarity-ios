# Codex Review Rules

- Use the OpenAI Codex plugin for Claude Code as the preferred independent code reviewer when it is installed.
- Prefer `/codex:review --background` for normal diff review.
- Prefer `/codex:adversarial-review --background <focus>` for design, security, data-loss, reliability, or concurrency risks.
- Use `/codex:status` and `/codex:result` to retrieve background results.
- Do not substitute Claude Opus for Codex review when Codex is available. Claude coordinates; Codex reviews.
- Treat Codex review output as external reviewer feedback, not as a replacement for tests.
- Do not enable the optional Codex review gate unless the user explicitly wants a monitored, potentially long-running review loop.
