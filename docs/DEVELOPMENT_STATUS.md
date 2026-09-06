# DEVELOPMENT STATUS

> Practical dashboard. Items describe what is known from the code, not aspirations.

## WORKING

- **Podcast RSS sermon sync** — `sync-podcast-sermons` imports RSS episodes as drafts; dedupe/update by stable RSS `source_guid` with audio URL fallback. Verified in code.
- **Manual sermon entry** — admin form; URL auto-routed to `audio_url`/`youtube_url`. Verified.
- **Audio playback** — in-app `expo-audio` player with slider + lock-screen metadata for `audio_url` sermons. Verified.
- **Admin CRUD** — events, announcements, sermons, ministries, leaders, contact, home wording. Verified.
- **Publishing** — draft-by-default with confirmation + validation. Verified.
- **Push notifications** — admin `send-push` → Expo fan-out → `notification_history`; deep-link routing on tap. Verified.
- **Visitor inbox** — public `submit-visitor` + admin triage (contacted/closed/reopen). Verified.
- **Content health** — dashboard flags past/expired/incomplete published content. Verified.
- **Admin security / RLS hardening** — `is_admin()` SECURITY DEFINER + `requireAdmin()` + table grants. Verified.
- **submit-visitor rate limiting** — server-side per-IP limit (3 / 10 min) before insert/email, atomic via `check_visitor_rate()`, fail-open. Implemented 2026-09-05 (Decision 011). `info.remoteAddr` trustworthiness requires production verification.

## IN PROGRESS / NEEDS ATTENTION

- **Removal of deprecated Squarespace ingestion** — DONE. The `sync-squarespace-sermons` function, its `config.toml` entry, and all active script/env references (`backend-deployment-check.mjs`, `backend-launch-gate.mjs`, `guided-deploy.mjs`, `live-production-check.mjs`, `.env.example`) have been removed. Remaining mentions are historical/archive only. Do NOT redeploy it.
- **`preacher` domain/schema mismatch** — type/lock-screen use `preacher`; no migration creates the column. Resolve deliberately (Decision 006); do not silently add.
- **Architectural documentation** — this `docs/` layer established; keep synchronized with future changes.
- **Maintainability of App.tsx** — monolith (~498 minified lines); high review/regression risk. Improve opportunistically, not by rewrite.
- **Navigation architecture** — custom state machine works but limits deep-linking; revisit only with a clear need.
- **Data-access architecture** — `supabase.from` calls embedded in UI; a thin data layer would help, but is not yet justified.

## BROKEN / FRAGILE

- **Squarespace/website sermon ingestion** — did not work reliably; now deprecated/removed (Decision 002/003). Root cause not diagnosed from static code.
- **`preacher` column drift** — referenced but absent from schema (see above).
- **Push send rate limit** — the 6-hour gap is enforced only in the client; no server-side guard.
- **Rate limiting is first-layer only** — per-IP (3/10 min) on submit-visitor; no global cap, CAPTCHA, or Turnstile yet. IP rotation/botnets can still bypass per-IP limits.
- **Hard-coded timezone** — `+02:00` baked into date handling.

## DEFERRED

- **YouTube automated ingestion** — retained as legacy infrastructure, but no longer the Admin source of truth.
- **Website sermon scraping** — not an acceptable default strategy (Decision 003).
- **Major architectural refactor** — not justified while current system works; prefer incremental change (see AI_RULES).
