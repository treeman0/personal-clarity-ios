# Model Selection

- Use Opus for judgment-heavy Claude roles: independent verification, risk review, architecture critique, security review, and contradiction handling.
- Use Sonnet for high-throughput maker roles: test writing, narrow implementation, wiki upkeep, and routine maintenance.
- Keep the Codex reviewer as Codex-backed review, not Claude Opus review. The `codex-reviewer` subagent may use Sonnet because its job is coordination; `/codex:review` or `/codex:adversarial-review` is the reviewer of record.
- Do not default every subagent to Opus. Loops can run many times, and cost and latency compound.
- Escalate a Sonnet role to Opus when the change involves security, data loss, concurrency, migrations, production incidents, unclear requirements, or expensive-to-reverse decisions.
- Keep the model choice visible in each subagent frontmatter so the tradeoff is explicit.
