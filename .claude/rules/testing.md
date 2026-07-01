# Testing And TDD

- For behavior changes, write or update a failing test before implementation when practical.
- Do not write tests that simply mirror the planned implementation.
- Run the smallest relevant test first, then broaden to the suite or integration checks as risk increases.
- If the project has no tests, add a characterization test or create a written verification note explaining the gap.
- The verifier role should inspect results independently from the implementer.
- Do not mark work complete while `.claude/state/needs-verification.json` is newer than the latest successful verification or waiver.

