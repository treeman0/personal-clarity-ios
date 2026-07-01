# Core Loop Rules

- A prompt produces an answer. A loop produces repeated sensing, action, verification, and memory updates.
- Every loop needs a goal, a budget, a verifier, and a stopping condition.
- Keep the main context clean. Delegate broad searches, log reading, and independent verification to subagents.
- Use `/compact` or start a fresh session when context is becoming noisy.
- Prefer short, reversible steps over large autonomous batches.
- Treat "done" as a claim until an independent check or test result supports it.

