# AI RULES — for any AI coding agent working on this repository

> Read this and the rest of `docs/` **before** making significant changes. These rules exist because the project is a production church platform where reliability and security outrank convenience.

## Orientation

1. **Read `docs/` first** — `PROJECT_CONTEXT`, `CURRENT_STATE`, `ARCHITECTURE`, `DECISIONS`, `DEVELOPMENT_STATUS`, `ROADMAP` — before any significant change.
2. **Code is the source of truth for CURRENT STATE.**
3. **`DECISIONS.md` is the source of truth for established architectural decisions.** Do not override a decision without explicit instruction and a logged reason.
4. **Never invent** database columns, tables, migrations, Edge Functions, environment variables, APIs, or dependencies. Verify against the repo first.

## Database discipline

5. Before changing the database: inspect existing migrations, inspect actual schema usage, identify **all** references, explain migration impact, and **never silently change schema**.
6. Distinguish domain concepts precisely: **preacher** ≠ **creator/uploader** ≠ **sermon title** ≠ **sermon source** ≠ **media URL**. Do not assume semantics (see `DECISIONS.md` 006 — do not add a `preacher` column until its meaning is defined).

## Security (non-negotiable)

7. **Never rely on client-side security** for authorization.
8. **Preserve server-side RLS and Edge Function authorization** (`is_admin()`, `requireAdmin()`). New privileged operations must be enforced server-side too.
9. **Do not expose secrets** in code, docs, screenshots, or messages. `.env` contents stay private; refer to variables by NAME only.
10. **Never put service-role keys in client code.** Client uses only `EXPO_PUBLIC_*` publishable config and function URLs.

## Architectural coherence

11. **Do not introduce a second architecture** just because it is easier for one feature. Work within the current architecture unless a `DECISIONS.md` entry says otherwise.
12. **Do not revive deprecated integrations** (e.g. Squarespace/RSS) without reviewing `DECISIONS.md` and getting explicit direction.
13. **YouTube remains the canonical sermon source** until a deliberate decision changes it.
14. **Podcast/RSS is future work** unless explicitly reactivated.
15. **Website scraping is not an acceptable default** integration strategy.
16. **Do not change multiple architectural layers in one task** unnecessarily.
17. When asked to implement something, **first identify which architectural layer owns the change** and inspect the relevant existing implementation before coding.

## Change discipline

18. **Prefer small, reversible changes.**
19. Before any major refactor, explain: the problem, current behavior, proposed architecture, risks, migration plan, and rollback strategy.
20. **Do not refactor merely because code is not aesthetically ideal.** The monolithic `App.tsx` is known debt — improve it opportunistically, not by rewrite.
21. **Protect working functionality.** Do not remove or break a working feature unless the requested change specifically requires it — and then explain why.
22. **Do not add libraries** unless there is a clear, justified reason.
23. **After changes, verify the affected flow** (type-check, and where possible run the flow) rather than assuming success.
24. **Keep `docs/` synchronized** with any meaningful architectural change.

## Priorities & uncertainty

25. **Security, data integrity, and content reliability rank above visual polish.**
26. **When uncertain, STOP** and state the uncertainty instead of guessing. Label unverifiable claims `UNVERIFIED` (see `CURRENT_STATE.md` conventions).

## Repository-specific notes an agent should know

- `git` is not reliably available in this workspace — do not assume it exists; check first. Rollback currently relies on `archive/` backups.
- `App.tsx` is heavily minified into long lines; edits must match exact text. Type-check with `npx tsc --noEmit` (note: `supabase/functions/**` and `archive/**` are excluded from the TS project).
- The app runs through a **development build** (`redpointchurch://`), not Expo Go; `expo-notifications` remote push needs a dev build.
- `sermons` supports both `audio_url` (in-app playback) and `youtube_url` (external watch). Preserve this dual-link model.
