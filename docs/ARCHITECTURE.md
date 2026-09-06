# ARCHITECTURE — Red Point Church App

> Current architecture is the source of truth. The "Architectural Direction" section is aspiration, NOT current state.

## High-level

```
┌─────────────────────────────────────────────────────────┐
│  APP  (Expo / React Native — single App.tsx)            │
│  custom state navigator · hooks state · direct queries  │
└──────────────┬──────────────────────────────────────────┘
               │  supabase-js (publishable key, EXPO_PUBLIC_*)
               ↓
┌─────────────────────────────────────────────────────────┐
│  SUPABASE                                               │
│  ┌───────────┐ ┌───────┐ ┌─────────┐ ┌───────────────┐  │
│  │ Postgres  │ │ Auth  │ │ Storage │ │ Edge Functions │  │
│  │  + RLS    │ │       │ │ church- │ │ (Deno)         │  │
│  │           │ │       │ │ media   │ │                │  │
│  └───────────┘ └───────┘ └─────────┘ └───────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Responsibilities

**Client (App.tsx)**
- Render public content and the staff admin area.
- Read published content; admins manage content via the same client with an authenticated session.
- Sermon playback (in-app audio via `expo-audio`, or external YouTube link).
- Push registration; navigation on notification tap.
- Never holds service-role or secret keys.

**Backend (Supabase)**
- Postgres stores all content; RLS decides row access.
- Auth = email/password; `public.admin_users` marks admins.
- Storage `church-media` hosts images (public read, admin write).
- Edge Functions do privileged work with the service-role key:
  public `register-device`, `submit-visitor`; admin `send-push`, `sync-podcast-sermons`, and retained legacy `sync-youtube-sermons`.

## Authentication & authorization

```
User ──signInWithPassword──▶ Supabase Auth ──▶ session (JWT)
Admin check (server-side, two layers):
  1) RLS:  public.is_admin()  (SECURITY DEFINER; admin_users not directly readable)
  2) Edge: requireAdmin()     (validates Bearer JWT + admin_users lookup via service role)
```

Authorization is **never** trusted to the client. UI hides admin actions, but enforcement is in RLS + Edge. See `DECISIONS.md` (005).

## Public vs admin access

| Role | Read | Write |
|---|---|---|
| anon / public | `published = true` rows; all `site_settings` | none |
| authenticated admin | everything | all content tables (RLS `is_admin()`) |
| Edge (service role) | all | all (bypasses RLS; guarded by `requireAdmin`) |

## Sermon ingestion (current)

```
Red Point Church podcast RSS feed
  → sync-podcast-sermons (admin-only)
  → normalize to sermons row (published=false draft)
  → app reads → list / Home card → SermonDetail
  → audio_url: in-app player | youtube_url: open externally
```

Podcast RSS is canonical (current source decision). The retained YouTube function is legacy and no longer used by the Admin sync path. Website scraping is not used.

## Media handling

Admin picks an image (`expo-image-picker`) → uploaded to `church-media/<kind>/...` → public URL stored on the row's `image_url`. RLS keeps uploads admin-only; reads are public.

## Data flow & publishing model

- **Public:** root `App.load()` fetches published events/announcements/sermons/site_settings in one `Promise.all`; pull-to-refresh re-runs it.
- **Admin:** `Admin.refresh()` fetches full (draft + published) content and operational data.
- **Publishing:** every content type is `published` boolean; UI defaults to **draft**, requires confirmation to publish, and validates required fields first.

## Architectural Direction (NOT current state)

The project should *gradually* move toward clearer separation of:

- **presentation** (screens/components),
- **navigation** (a real navigator),
- **data access** (a query/repository layer instead of UI-embedded `supabase.from`),
- **domain logic** (typed models, publishing rules),
- **backend integrations** (Edge Functions behind a thin client).

This is a direction to work toward incrementally as features are touched — **not** a refactoring that has already happened, and not a reason to rewrite working code. See `AI_RULES.md` before proposing it.
