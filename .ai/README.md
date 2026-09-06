# Red Point AI Engineering Control Plane

This directory is the repository memory for AI-assisted engineering. Chat history is not authoritative.

## Required entry point

1. Read `PROJECT_STATE.md`, `ARCHITECTURE.md`, `DATABASE.md`, `SECURITY.md`, `TASKS.md`, `WORKFLOWS.md`, and `KNOWN_LIMITATIONS.md`.
2. Select one task from `TASKS.md` whose dependencies are satisfied.
3. Follow `runbooks/AI_EXECUTION_LOOP.md`.
4. Record evidence before claiming a task is proven.

## Truth hierarchy

When sources conflict, use: production database state, production application behavior, source code, migrations, tests, documentation, then chat assumptions. Observe, reconcile, document, and plan a safe change; do not alter production to match documentation.

`IMPLEMENTED` means code exists. `PROVEN` requires reproducible evidence for the acceptance criteria.
