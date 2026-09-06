# AI Execution Loop

1. Read `.ai/PROJECT_STATE.md`, `ARCHITECTURE.md`, `DATABASE.md`, `SECURITY.md`, `TASKS.md`, `WORKFLOWS.md`, and `KNOWN_LIMITATIONS.md`.
2. Reconcile code, database, migrations, RLS, functions, grants, UI path, integrations, and tests.
3. Select one dependency-ready task.
4. Write explicit acceptance criteria in the task/evidence record.
5. Implement the minimum safe change.
6. If schema changes, create one additive migration; inspect, dry-run, deploy only intended SQL, and verify.
7. Test authorized, unauthorized, anonymous, ownership, and role boundaries.
8. Trace UI -> Supabase -> RLS -> persistence -> refresh -> error recovery.
9. Run regression checks.
10. Write evidence with commands, outputs, expected/actual results, and unproven items.
11. Update project state, tasks, changelog, limitations, and handoff.
12. Identify the next task without silently expanding scope.

Never promote IMPLEMENTED to PROVEN without acceptance-criteria evidence.
