# DECISIONS — architectural decision log

> Established decisions are the source of truth for architecture. Revisit deliberately, not casually.
> Dates are only recorded where known; otherwise marked UNVERIFIED.

---

## DECISION 001 — Podcast RSS is the canonical automated sermon source

- **Status:** Active.
- **Decision:** The Red Point Church Pinetown podcast RSS feed via `sync-podcast-sermons` is the authoritative automated sermon source.
- **Reason:** The feed contains the church's sermon metadata and hosted audio media, including stable RSS GUIDs for idempotent ingestion.
- **Consequences:** Sermons are imported as drafts with `audio_url` playback and `source_guid` deduplication. The retained YouTube function is no longer the Admin ingestion path.
- **Date:** 2026-09-06.

## DECISION 002 — Website scraping is deprecated; RSS is a deliberate backend source

- **Status:** Active.
- **Decision:** The church website is not scraped by the app. The dedicated `sync-podcast-sermons` Edge Function fetches the supplied RSS feed server-side.
- **Reason:** RSS provides a stable content contract without coupling the mobile app to website HTML.
- **Action:** Keep RSS parsing server-side and leave the retained YouTube function outside the active Admin source path.
- **Future:** Add further sources only through an explicit architectural decision.
- **Date:** 2026-09-06.

## DECISION 003 — The church website is not the canonical sermon source

- **Status:** Active.
- **Reason:** Website scraping is fragile and couples the app to website implementation details.
- **Consequences:** No scraping defaults; the website remains a marketing surface, not a data API.
- **Date:** UNVERIFIED.

## DECISION 004 — Home screen prioritizes the latest sermon

- **Status:** Active.
- **Order:** 1) latest sermon 2) latest announcement 3) this Sunday 4) "New here?".
- **Reason:** Specifically requested by church leadership.
- **Consequences:** Changes to Home must preserve this ordering unless leadership says otherwise.
- **Date:** UNVERIFIED.

## DECISION 005 — Security is enforced server-side

- **Status:** Active.
- **Reason:** Client-side admin checks alone are insufficient.
- **Implementation:** RLS via `public.is_admin()` (`SECURITY DEFINER`) on all content tables; `requireAdmin()` in Edge Functions; service-role key only inside Edge Functions; public reads limited to `published = true`.
- **Consequences:** Any new privileged operation must add/keep server-side enforcement, not just hide UI.
- **Date:** UNVERIFIED (branch is named for this hardening).

## DECISION 006 — Do not add a `preacher` database field yet

- **Status:** Active.
- **Reason:** Creator/uploader and the actual preacher are distinct concepts; the RSS `creator` field is not reliably the preacher. The domain meaning must be defined first.
- **Current behaviour:** `Sermon.preacher` exists in the type and is used for audio lock-screen metadata, but **no migration creates the column**; podcast imports folded it into `description`. Treat as known drift — resolve deliberately, do not silently add.
- **Date:** 2026-09-05.

---

## Additional decisions identified from the repository

## DECISION 007 — Custom state-based navigation (no React Navigation yet)

- **Status:** Active (current implementation).
- **Reason:** App began small; a `Screen` union + `switch` was sufficient.
- **Consequences:** Cheap, but limits deep-linking/gestures and contributes to the monolith; revisit only with a clear need (see ROADMAP Phase 2).
- **Date:** UNVERIFIED.

## DECISION 008 — Draft-by-default publishing

- **Status:** Active.
- **Reason:** Protects the public app from half-finished content.
- **Consequences:** All create flows save drafts first; publish requires confirmation + validation.
- **Date:** UNVERIFIED.

## DECISION 009 — Single-file application (App.tsx)

- **Status:** Active (current implementation, recognised as debt).
- **Reason:** Simplicity at early stages.
- **Consequences:** Maintainability risk; do not grow it further without need; see ROADMAP Phase 2.
- **Date:** UNVERIFIED.

## DECISION 010 — Service-role and third-party secrets never enter the client

- **Status:** Active.
- **Reason:** Security.
- **Consequences:** Client uses only `EXPO_PUBLIC_*` publishable config + function URLs; `YOUTUBE_API_KEY`, Resend keys, and the service-role key live only in Supabase secrets. Never place them in `.env`, `app.json`, source, or docs.
- **Date:** UNVERIFIED.

## DECISION 011 — Server-side rate limiting on submit-visitor (first layer)

- **Status:** Active.
- **Decision:** The public `submit-visitor` Edge Function enforces a server-side per-client-IP limit of **3 submissions per 10-minute window** before any database insert or email.
- **Reason:** It is the only internet-facing endpoint that both persists attacker-controlled data and triggers outbound email (Resend), making it the most practical abuse vector found in the security audit.
- **Implementation:** atomic `public.check_visitor_rate()` (SECURITY DEFINER, UPSERT … RETURNING) against a locked-down `public.visitor_rate_limits` table (RLS enabled, no policies, no grants; service-role only). Client IP comes from `Deno.serve` `info.remoteAddr`; spoofable headers are not trusted. Limiter **fails open** so a transient limiter outage never silently drops a real visitor. Exceeding the limit returns HTTP 429 with no row and no email.
- **Consequences / caveats:** this is deliberately the first layer only — no global cap, no CAPTCHA/Turnstile yet. IP rotation / botnets can bypass per-IP limits. Whether `info.remoteAddr` is the true end-user IP (versus the relay) **requires production verification** before being relied on as the primary key.
- **Date:** 2026-09-05.
