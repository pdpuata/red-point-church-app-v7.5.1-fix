# CURRENT STATE — what actually exists right now

> Verified against the code. Legend: FACT (in code/config) · INFERENCE · UNVERIFIED.
> No secrets or `.env` values are recorded here.

## Branch / version

- **Branch (declared):** `v7.5.2-admin-security-fix`. INFERENCE from folder name + `APP_VERSION = '7.5.2'`.
- **Git:** NOT available in this workspace (no `git` binary, no `.git` directory). FACT. History is kept as manual backups in `archive/` and per-version notes `V6.x–V7.4.md`.
- **App code root:** `v7.5.1-fix/` (folder name lags the 7.5.2 version).

## Technology stack

| Layer | Value | Source |
|---|---|---|
| Framework | Expo SDK **57.0.17** | `package.json` |
| React Native | **0.86.0** | `package.json` |
| React | **19.2.3** | `package.json` |
| TypeScript | **~5.9.2**, `strict: true` | `tsconfig.json` |
| Backend | Supabase (Postgres + RLS + Auth + Storage + Edge Functions) | `supabase/` |
| Edge runtime | Deno | `supabase/functions/**` |
| App entry | `node_modules/expo/AppEntry.js` → `RootApp` in `App.tsx` | `package.json` |

Key dependencies: `@supabase/supabase-js 2.112.4`, `expo-audio` (background playback on), `expo-notifications`, `expo-image-picker`, `expo-constants`, `expo-device`, `expo-dev-client`, `@react-native-community/slider 5.2.0`, `expo-asset`, `expo-status-bar`.

`tsconfig.json` **excludes** `supabase/functions/**` and `archive/**` from type-checking.

## Application architecture

- **Single-file app.** `App.tsx` (~498 lines, heavily minified long lines) contains every screen, component, style, the navigator, and the admin area. FACT.
- **Navigation:** custom state machine, **not** React Navigation. `Screen` union type + `useState<Screen>('Home')` + `useMemo switch(screen)`. A bottom tab bar shows only for `Home | Events | Sermons | More`. FACT.
- **State:** React hooks only. No Redux/Zustand. FACT.
- **Data access:** direct `supabase.from(...)` calls from UI. Public data in root `App.load()`; admin data in `Admin.refresh()`. FACT.
- **Error handling:** `AppErrorBoundary` + full-screen load-error + `staleBanner` on partial failure. Logging is `console.*` only. FACT.

## Backend

- **Tables:** `events, announcements, sermons, ministries, leaders, visitor_submissions, admin_users, site_settings, device_tokens, notification_history, visitor_rate_limits`. FACT (`schema.sql` + migrations). `visitor_rate_limits` is internal rate-limit state (RLS enabled, no policies/grants; service-role only).
- **Auth:** Supabase email/password, signed in inside `Admin`. FACT.
- **Authorization:** user is admin iff `auth.uid() ∈ public.admin_users`. Enforced server-side by RLS via `public.is_admin()` (`SECURITY DEFINER`) and by `requireAdmin()` in Edge Functions. FACT.
- **RLS:** public (`anon`/`authenticated`) read only `published = true` content rows; `site_settings` fully readable. Writes restricted to admins. FACT.
- **Grants:** `20260905_table_grants.sql` grants table privileges, then RLS governs rows (grant-then-RLS model). FACT.
- **Storage:** `church-media` bucket — public read, admin-only write/update/delete. FACT (`v2.6_media_upload.sql`).
- **Edge Functions** (`supabase/functions/`, shared `_shared/cors.ts` + `_shared/supabase.ts`):
  - `register-device` — public, stores Expo push tokens.
  - `submit-visitor` — public, stores visitor + optional Resend email. **Protected by server-side per-IP rate limiting (3 / 10 min) before insert/email** (Decision 011).
  - `send-push` — admin, Expo push fan-out + writes `notification_history`.
   - `sync-podcast-sermons` — admin, **active canonical** sermon ingestion from the church RSS feed.
   - `sync-youtube-sermons` — retained legacy admin function, no longer used by the Admin sync path.
- **JWT policy** (`config.toml`): public functions `verify_jwt=false`; `send-push`, `sync-youtube-sermons`, and `sync-podcast-sermons` `verify_jwt=true`.

## Screens / features

Events, Event Detail, Sermons (search + year filter), Sermon Detail (audio player / YouTube), Announcements, Ministries, Leadership, Calendar, Contact (configurable), Sunday details, New Here, Visitor Form, Privacy, Search, Diagnostics, More, and Admin. FACT.

## Admin functionality

Reached via `More` → "STAFF / ADMIN" → sign-in gate. Modes: dashboard, event, announcement, sermon, visitors, notify, home, preview, ministries, ministry, leaders, leader, contact, sunday, health, release. Capabilities: CRUD + publish/unpublish for all content; edit home wording + contact details; visitor triage; send push; upload images; content-health audit; Sunday-readiness and release checklists; "CLEAR ALL SERMONS (FRESH START)". Publishing is gated behind confirmations; drafts are the default. FACT.

## Sermon architecture (explicit trace)

```
SOURCE      YouTube Data API v3 (channel UCEN1U4zn9RnvEkykRrerg5Q)
   ↓
INGESTION   sync-youtube-sermons Edge Function (requireAdmin)
            channels → uploads playlist → playlistItems → videos
   ↓
TRANSFORM   map video.snippet → { title, description, preached_at=publishedAt,
            youtube_url=watch?v=ID, image_url=ytimg hqdefault, published=false }
   ↓
DATABASE    public.sermons { id,title,description,preached_at,
            audio_url,youtube_url,published,image_url,created_at,updated_at }
            dedupe via youtube_url (maybeSingle + unique index)
   ↓
API/ACCESS  root load(): select id,title,description,preached_at,
            audio_url,youtube_url,published,image_url
   ↓
APP         sermons state → Sermons list / Home latest-sermon card
   ↓
UI          SermonDetail
   ↓
PLAYBACK    audio_url → in-app expo-audio player (Slider + lock-screen meta)
            youtube_url → "WATCH ON YOUTUBE" external Linking
```

Manual entry: Admin → Sermons URL field auto-routes to `youtube_url` if it matches `/youtu\.?be/i`, else `audio_url`. FACT.

## Sermon sources — status

- **`sync-podcast-sermons` is ACTIVE and is the canonical automated source.** FACT.
- **`sync-youtube-sermons` is retained but no longer used for automated sermon discovery.** FACT.
- **`sync-squarespace-sermons` is DEPRECATED and has been removed from the active codebase** (Decision 002). Podcast/RSS is **future work**, not current architecture. The church website is **not** a sermon source (Decision 003).
- Imported YouTube sermons are created as **drafts** for staff review. FACT.

## Important files

`App.tsx`, `lib/supabase.ts`, `supabase/schema.sql`, `supabase/migrations/20260903_000002_admin_rls_fix.sql`, `supabase/migrations/20260905_table_grants.sql`, `supabase/migrations/20260904_sermon_audio_source.sql`, `supabase/config.toml`, `supabase/functions/_shared/supabase.ts`, `supabase/functions/sync-youtube-sermons/index.ts`, `supabase/functions/send-push/index.ts`, `package.json`, `.env.example`, `supabase/DEPLOYMENT_ORDER.md`.

## Known technical debt

- Monolithic minified `App.tsx`. FACT.
- No navigation library. FACT.
- Direct Supabase calls from UI (no data-access layer). FACT.
- No automated tests; manual `scripts/*.mjs` checks only. FACT.
- No git in the delivery workspace; manual `archive/` backups are the only rollback. FACT.

## Known broken / fragile areas

- **`preacher` schema/code mismatch:** `Sermon.preacher` and the (now removed) podcast function reference a `preacher` column, but **no migration creates it**. It is currently folded into `description` as `"Preacher: X"`. Domain meaning unresolved — do NOT add the column yet (Decision 006). FACT.
- Date/time handling is hard-coded to `+02:00`. FACT.
- Push send has no server-side rate limit (a 6-hour warning is client-side only). FACT.
