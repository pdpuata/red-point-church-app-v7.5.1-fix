# Red Point Church App — Current Project Snapshot

> Read-only audit of the working tree as it exists NOW. The codebase is the source of truth.
> Legend: **FACT** = directly in code/config · **INFERENCE** = strongly suggested · **UNKNOWN** = not established from code.
> No secrets, `.env` values, keys, or tokens are included.

## 1. Repository State

- **Branch (declared):** `v7.5.2-admin-security-fix` — **INFERENCE** from the parent folder name `red-point-church-app-v7.5.2-admin-security-fix` and `APP_VERSION = '7.5.2'` in `App.tsx`.
- **Git availability:** **FACT** — `git` is NOT installed on this machine and there is **no `.git` directory** in the workspace root or the app folder. This is a plain file copy, not a live git checkout.
- **Recent commits:** **UNKNOWN** — no git history available.
- **Working tree status / uncommitted changes:** **UNKNOWN** via git. **FACT** — change history is instead captured by manual backups in `archive/` (see §15) and per-version markdown notes (`V6.1.md` … `V7.4.md`).
- The deployable app lives in the nested folder `v7.5.1-fix/` (despite version 7.5.2). All paths below are relative to `v7.5.1-fix/`.

## 2. Technology Stack

- **Framework/runtime:** Expo SDK `57.0.17` on React Native `0.86.0`, React `19.2.3`. **FACT** (`package.json`).
- **Language:** TypeScript `~5.9.2`, `strict: true`. **FACT** (`tsconfig.json`). `tsconfig` **excludes** `supabase/functions/**` and `archive/**` from type-checking.
- **Entry point:** `node_modules/expo/AppEntry.js` → root-`export default RootApp` in `App.tsx`. **FACT**.
- **Major dependencies** (`dependencies`): `@supabase/supabase-js 2.112.4`, `expo-audio` (background playback enabled), `expo-notifications`, `expo-image-picker`, `expo-constants`, `expo-device`, `expo-dev-client`, `@react-native-community/slider 5.2.0`, `expo-asset`, `expo-status-bar`. **FACT**.
- **Backend:** Supabase (Postgres + RLS + Edge Functions on Deno + Storage). **FACT**.
- **Build/submit:** EAS (`eas.json`) — profiles `development` (dev-client), `preview` (internal APK), `production` (autoIncrement). App scheme `redpointchurch`, bundle id `com.redpointchurch.app` (iOS+Android). **FACT**.

## 3. Project Structure

```
v7.5.1-fix/
  App.tsx                  # THE ENTIRE mobile app (single file, ~498 lines, minified long lines)
  lib/supabase.ts          # Supabase client init (null if env missing)
  app.json / eas.json / tsconfig.json / package.json
  .env.example             # public env var names only
  supabase/
    schema.sql             # baseline DDL + RLS + indexes
    config.toml            # per-function verify_jwt flags
    v2.6 … v6.2 .sql       # incremental migrations
    migrations/            # 5 timestamped migrations (baseline, admin_rls_fix, production_backend, sermon_audio_source, table_grants)
    functions/             # 5 edge functions + _shared helpers
  scripts/*.mjs            # many deployment/verification CLIs (no-DB, config checks)
  archive/*.tsx            # 5 manual App.tsx backups (the only "history")
  docs/PROJECT_SNAPSHOT.md # this file
  V6.x–V7.4.md             # per-version human notes
```

## 4. Application Architecture

- **Single-file app.** Every screen, component, style, and the root navigator live in `App.tsx` (~144 KB, minified into very long lines). **FACT**.
- **State management:** React `useState`/`useMemo`/`useEffect` only. No Redux/Zustand/etc. **FACT**.
- **Data fetching:** direct `supabase.from(...)` calls in the root `App` `load()` (Promise.all over `events`, `announcements`, `sermons`, `site_settings`) and a separate `refresh()` inside the `Admin` component. **FACT**.
- **Error handling:** `AppErrorBoundary` (class component) wraps the app; load failures show a "CONNECTION PROBLEM" screen; partial failures show a `staleBanner`. **FACT**.
- **Logging:** `console.log`/`console.error`/`console.warn` only. No analytics/crash service. **FACT**.

## 5. Navigation

- **Custom state-based navigator** — NOT React Navigation. A `Screen` union type and `const [screen,setScreen]=useState('Home')` drive a `useMemo` `switch(screen)` that renders the active screen. **FACT**.
- **Bottom tab bar** rendered only for the 4 "primary" screens `Home | Events | Sermons | More`. All other screens (`EventDetail`, `SermonDetail`, `Search`, `Ministries`, `Leadership`, `Calendar`, `Contact`, `Sunday`, `New`, `VisitorForm`, `Announcements`, `Privacy`, `Diagnostics`, `Admin`) are reached via in-screen navigation. **FACT**.
- **Deep-link from push:** a `Notifications.addNotificationResponseReceivedListener` reads `data.screen` and routes to `Home/Events/Announcements/Sermons`. **FACT**.

## 6. Authentication & Authorization

- **Auth:** Supabase email+password via `supabase.auth.signInWithPassword`, inside `Admin`. Session kept by supabase-js; `onAuthStateChange` tracked. Public screens need no login. **FACT**.
- **Admin identity:** a user is an admin iff their `auth.users.id` exists in `public.admin_users`. **FACT**.
- **Server-side enforcement:** `public.is_admin()` is a `SECURITY DEFINER` SQL function used by RLS policies (so `admin_users` itself stays unreadable). Edge Functions additionally call `requireAdmin()` which validates the Bearer JWT and checks `admin_users` with a service-role client. **FACT** — authorization is enforced **both** server-side (RLS + Edge) and in the UI.
- **Two-layer grant model:** `20260905_table_grants.sql` grants table privileges to `anon`/`authenticated`, then RLS policies decide row access. **FACT**.

## 7. Admin Architecture

- Reached via `More` → "STAFF / ADMIN" → `Admin` component → sign-in gate → `mode` state dashboard. **FACT**.
- **Admin modes:** `dashboard, event, announcement, sermon, visitors, notify, home, preview, ministries, ministry, leaders, leader, contact, sunday, health, release`. **FACT**.
- **Capabilities:** CRUD + publish/unpublish for events, announcements, sermons, ministries, leaders; edit home wording + contact details (`site_settings`); visitor inbox triage; send push notifications; image upload to Storage; content-health audit; Sunday-readiness and release checklists. **FACT**.
- **Publish safety:** most `save*` functions gate publishing behind confirmation alerts and required-field validation; drafts are the default. **FACT**.

## 8. Security Assessment

| Area | Rating | Evidence |
|---|---|---|
| Admin authorization | **SECURE** | RLS via `is_admin()` SECURITY DEFINER + Edge `requireAdmin()`; not client-only. |
| Public read model | **SECURE** | RLS: `anon/authenticated` read only `published = true` rows; `site_settings` fully readable (by design). |
| Service-role key | **SECURE** | used only inside Edge Functions (`adminClient()`), never shipped to the app. |
| Secrets hygiene | **SECURE** | `.env`/`.env.*`/`.supabase.production.env` git-ignored; docs repeatedly forbid committing secrets. |
| Public Edge endpoints | **PROBABLY SECURE** | `register-device`/`submit-visitor` have `verify_jwt=false` by design; both validate input & cap lengths. CORS is `*` (acceptable for public endpoints, worth noting). |
| Push sending | **PROBABLY SECURE** | admin-gated, but no server-side rate limit (app warns if a notification was sent < 6 h ago — client-side only). |
| `notification_history` | **WEAK/INCONSISTENT** | baseline policy allows admin SELECT+INSERT; Edge function writes via service role. SELECT-only would suffice for the UI. |
| Exposed secrets in repo | **NONE FOUND** | only var NAMES in `.env.example`. |
| Privilege escalation | **PROBABLY SECURE** | no client path writes `admin_users`; inserts are done manually in Supabase. |

## 9. Sermon Architecture

Complete current flow:

```
SOURCE A: YouTube Data API v3 (ACTIVE)
  channelId UCEN1U4zn9RnvEkykRrerg5Q → uploads playlist → playlistItems → videos
  Edge fn sync-youtube-sermons (requireAdmin) → map snippet → INSERT sermons
     { title, description, preached_at=publishedAt, youtube_url=watch?v=ID,
       image_url=ytimg hqdefault, published=false }
  dedupe by youtube_url (maybeSingle select + unique index)
SOURCE B: Apple Podcast RSS → Squarespace feed (REMOVED 2026-09-05 — Decision 002)
  Edge fn sync-squarespace-sermons: iTunes lookup id 1011685201 → feedUrl
     (fallback https://www.redpointchurch.com/pinetown-podcast-feed?format=rss)
  regex-parse <item> XML → title/itunes:author/pubDate/enclosure url
     → INSERT/UPDATE sermons { title, description="Preacher: X", preached_at,
        audio_url, image_url, published=false }   dedupe by audio_url
SOURCE C: Manual (Admin → Sermons form) — URL field auto-routed:
     /youtu\.?be/i → youtube_url, else audio_url
DATABASE: public.sermons { id,title,description,preached_at,audio_url,youtube_url,published,image_url,created_at,updated_at }
APP LOAD: root load() selects id,title,description,preached_at,audio_url,youtube_url,published,image_url
UI: Sermons list / SermonDetail
     audio_url → in-app expo-audio player (Slider + lock-screen metadata)
     youtube_url → "WATCH ON YOUTUBE" external Linking
```

**NOTE (schema drift):** the `Sermon` type and the podcast function reference a `preacher` column, but **no migration creates `preacher`** — it is folded into `description` ("Preacher: X"). **FACT** — likely latent bug / incomplete field.

## 10. Sermon Sources

### YouTube
**ACTIVE & WORKING.** `sync-youtube-sermons` is the wired source (Admin → Sermons → "SYNC YOUTUBE NOW" → `EXPO_PUBLIC_SYNC_YOUTUBE_FUNCTION_URL`). Requires server secret `YOUTUBE_API_KEY`. **FACT**.

### Podcast/RSS
**REMOVED.** The Squarespace/podcast-RSS ingestion function `sync-squarespace-sermons` was deleted from the active codebase on 2026-09-05 (Decision 002). The `EXPO_PUBLIC_SYNC_SQUARESPACE_FUNCTION_URL` env var and all active script references were removed at the same time. Podcast/RSS is deferred future work, not current architecture.

### Red Point Church Website
**BROKEN / ABANDONED.** The Squarespace feed (`redpointchurch.com/pinetown-podcast-feed?format=rss`) is the fallback RSS target; `sermons.html` (a saved Squarespace `/sermons` page) and `scripts/test-squarespace-crawl.ps1` indicate an attempted website/scrape approach that "did not work correctly," prompting the revert to YouTube. **INFERENCE** (from file presence + your note).

### Other
- Manual admin creation — **WORKING**. In-app audio playback for `audio_url` sermons — **WORKING**. No scheduled/background ingestion (sync is manually triggered). **FACT**.

## 11. Home Screen

- Implemented by `Home` in `App.tsx`. **Product order (top→bottom):** greeting + configurable heading → **LATEST SERMON (primary)** → LATEST UPDATE (announcement) → THIS SUNDAY → "New to Red Point?" link. **FACT**.
- Latest sermon = newest `published` sermon by `preached_at`; tapping it opens `SermonDetail` in-app (`selectSermon` + navigate). Shows sermon `image_url` or a ▶ placeholder; action label switches LISTEN (audio) / WATCH (youtube). **FACT**.
- Latest update = newest non-expired published announcement → navigates to `Announcements`. **FACT**.
- Configurable text comes from `site_settings` (greeting, heading, etc.) via `defaultHomeConfig`. **FACT**.
- States: full-screen loading; full-screen error when nothing loads; `staleBanner` on partial failure; "No sermon yet / TAP TO OPEN SERMONS" empty state. **FACT**.

## 12. Data & Backend Architecture

- **DB tables:** `events, announcements, sermons, ministries, leaders, visitor_submissions, admin_users, site_settings, device_tokens, notification_history`. **FACT**.
- **Storage:** `church-media` bucket (public read; admin-only write/update/delete). **FACT** (`v2.6_media_upload.sql`).
- **Edge Functions (Deno):** `register-device` (public), `submit-visitor` (public, optional Resend email), `send-push` (admin, Expo push API, writes `notification_history`), `sync-youtube-sermons` (admin). Shared: `_shared/cors.ts`, `_shared/supabase.ts` (`adminClient` + `requireAdmin`). `sync-squarespace-sermons` was removed 2026-09-05 (Decision 002). **FACT**.
- **JWT policy** (`config.toml`): public functions `verify_jwt=false`; `send-push`, both syncs `verify_jwt=true`. **FACT**.

## 13. Current Features

Events, Announcements (important/expiry), Sermon library (search + year filter + audio player + YouTube watch), Ministries, Leadership, Calendar, Contact (configurable), Visitor form + inbox, Push notifications (send + history + deep-link), Home (configurable), Admin dashboard with content-health / Sunday-readiness / release checklists, image uploads, in-app Diagnostics screen. **FACT**.

## 14. Current Problems / Known Limitations

- **Squarespace/website sermon ingestion is deprecated and its code has been removed** (revert to YouTube). **FACT**.
- **`preacher` column referenced but never created** in any migration → podcast-synced sermons store preacher only inside `description`. **FACT**.
- Single ~498-line minified `App.tsx` is hard to navigate/review (long-line truncation). **FACT**.
- No automated tests; verification is via `scripts/*.mjs` config checks and manual device testing. **FACT**.
- No git in this workspace → change tracking relies on manual backups.

## 15. Recent Changes on This Branch

**Established from `archive/` backups + current code (no git):**

- **Sermon source reverted YouTube ← Squarespace.** `App-before-squarespace-sermon.tsx` (YouTube-only) vs current: current re-points the sync button to `sync-youtube-sermons`; the podcast function has since been removed (2026-09-05, Decision 002). **FACT**.
- **Dual sermon link model added:** `Sermon` now has both `audio_url` AND `youtube_url`; `20260904_sermon_audio_source.sql` added `audio_url` + unique index. App reads both; detail screen plays audio in-app or opens YouTube. **FACT**.
- **In-app audio player added** (`expo-audio`, Slider, lock-screen metadata) — new vs the YouTube-only backup. **FACT**.
- **Home latest-sermon card** enhanced (image, LISTEN/WATCH label, in-app open) and general Home cleanup. **FACT**.
- **Admin "CLEAR ALL SERMONS (FRESH START)"** bulk-delete + per-sermon delete added. **FACT**.
- **Admin security hardening** is the branch's namesake: `20260903_000002_admin_rls_fix.sql` introduced `is_admin()` SECURITY DEFINER; `20260905_table_grants.sql` added table grants. **INFERENCE** (folder name + migration content).
- **Cleanup (2026-09-05):** the deprecated `sync-squarespace-sermons` Edge Function, its `config.toml` entry, the `EXPO_PUBLIC_SYNC_SQUARESPACE_FUNCTION_URL` env var, and all active script references were removed. Historical mentions survive only in `archive/`, `sermons.html`, `scripts/test-squarespace-crawl.ps1`, and the `V*.md` notes. **FACT**.

## 16. Architectural Risks

- **P0** — *none observed that is actively exploitable from the code reviewed.*
- **P1 (RESOLVED 2026-09-05)** — Deprecated Squarespace/RSS ingestion has been removed from the active codebase; only historical/archive mentions remain.
- **P1** — `preacher` field drift (used in code, absent from schema) → silent data loss for podcast sermons.
- **P2** — Monolithic minified `App.tsx` (~144 KB, all screens) → high regression risk, poor reviewability, merge-unfriendly.
- **P2** — No version control in the delivery workspace; manual `archive/*.tsx` backups are the only rollback → high operational risk.
- **P2** — Push sending has no server-side rate-limit (6-hour rule is client-side only) → accidental spam possible.
- **P3** — CORS `Allow-Origin: *` on all Edge Functions (fine for public, but note for admin functions).
- **P3** — No automated tests / CI; correctness rests on manual checks.

## 17. Incomplete / Fragile Areas

- Regex-based RSS/XML parsing was used by the removed `sync-squarespace-sermons`; it is no longer part of the active codebase. **FACT**.
- `notification_history` insert allowed from client (admin) though only the Edge function should write it. **WEAK**.
- Hard-coded timezone `+02:00` in date handling; hard-coded fallbacks (events/announcements/church details) baked into `App.tsx`. **FACT**.
- Sermon dedupe depends on unique indexes existing in the live DB; if migrations weren't all applied, duplicates/published-reset could occur. **INFERENCE**.
- `submit-visitor` email only sends if 3 secrets configured; otherwise silently stores. **FACT** (by design, but operationally silent).

## 18. Important Files for External Architect

1. **`App.tsx`** — the entire app: navigation, all screens, admin, sermon UI, data loading. The single most important file.
2. **`lib/supabase.ts`** — client init; shows env-based null-safe pattern.
3. **`supabase/schema.sql`** — full data model + RLS public/admin policies.
4. **`supabase/migrations/20260903_000002_admin_rls_fix.sql`** — `is_admin()` SECURITY DEFINER; core of the admin-security model.
5. **`supabase/migrations/20260905_table_grants.sql`** — grant-then-RLS two-layer model.
6. **`supabase/functions/_shared/supabase.ts`** — `adminClient()` + `requireAdmin()`; server-side authz for Edge Functions.
7. **`supabase/functions/sync-youtube-sermons/index.ts`** — ACTIVE sermon ingestion.
8. **`supabase/functions/_shared/cors.ts`** — shared CORS headers for all Edge Functions. (Note: `sync-squarespace-sermons` was removed 2026-09-05 — Decision 002.)
9. **`supabase/migrations/20260904_sermon_audio_source.sql`** — the audio_url dual-link model.
10. **`supabase/config.toml`** — per-function JWT policy (public vs admin endpoints).
11. **`supabase/functions/send-push/index.ts`** — push fan-out + history + admin gating.
12. **`package.json`** — stack, versions, and the many `verify:*`/`deploy:*` scripts.
13. **`supabase/v2.6_media_upload.sql`** — Storage bucket + media RLS.
14. **`.env.example`** — the complete list of public env var NAMES the app needs.
15. **`supabase/DEPLOYMENT_ORDER.md`** — migration order + admin bootstrap + storage setup.

## 19. Questions / Unknowns

- Exact git branch/commit/diff — **UNKNOWN** (no git in workspace).
- Which migrations have actually been applied to the live production DB — **UNKNOWN** from code alone.
- Whether `sync-squarespace-sermons` is still deployed on the live Supabase project — **UNKNOWN** (removed from this repo on 2026-09-05; a deployed remote copy, if any, is not visible from code).
- Whether `YOUTUBE_API_KEY` and Resend secrets are set in the live project — **UNKNOWN** (and must not be confirmed here).
- Root cause of the Squarespace fetch failure — **UNKNOWN** (not diagnosable from static code).

## 20. Executive Summary

1. **What:** A single-codebase Expo/React-Native mobile app for Red Point Church (events, announcements, sermons, ministries, leaders, visitors, push) with an in-app staff admin panel, backed by Supabase.
2. **Architecture:** One ~498-line `App.tsx` (custom state-based navigator, no React Navigation), Supabase Postgres + RLS + Storage + 5 Deno Edge Functions, security via a `is_admin()` SECURITY DEFINER function + per-function JWT flags.
3. **Recently changed:** Sermon source reverted from a broken Squarespace/podcast-RSS attempt back to YouTube; a dual `audio_url`/`youtube_url` sermon model, an in-app `expo-audio` player, an enhanced Home latest-sermon card, an admin "clear all sermons" reset, and admin-RLS/table-grant hardening.
4. **Working:** YouTube sermon sync; manual sermon entry; audio playback; full admin CRUD/publish; push notifications; visitor inbox; content-health tools; public read-only content via RLS.
5. **Broken/fragile:** Squarespace/RSS ingestion (bypassed, code still deployed); `preacher` column referenced but never migrated; no git in the delivery workspace; monolithic minified `App.tsx`.
6. **Top 3 issues:** (a) reconcile/remove the dead podcast ingestion path; (b) fix the `preacher` schema drift; (c) establish real version control + break up `App.tsx`.
7. **Before the next change an architect should know:** authorization is genuinely server-side (RLS + Edge), the sermon model intentionally supports both audio and YouTube links, YouTube is the live sermon source, and all admin UI flows default to draft-then-publish.
