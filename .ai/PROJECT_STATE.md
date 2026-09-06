# Project State

Updated: 2026-09-05

## Project

Red Point Church

## Stack

Expo, React Native, TypeScript, Supabase, PostgreSQL, Supabase Edge Functions, Supabase Storage, EAS.

## Architectural reality

- `App.tsx` is the monolithic screen/state/auth surface and uses a custom `Screen` switch.
- `lib/supabase.ts` creates the publishable-key client; privileged keys belong only in Edge Functions.
- `lib/music.ts` contains manual Music domain types.
- `supabase/migrations/` is the canonical additive schema history.
- Edge Functions: `register-device`, `send-push`, `submit-visitor`, `sync-youtube-sermons`.
- Auth is Supabase Auth. Global administration uses `admin_users` and `public.is_admin()`.
- RLS is the database authorization boundary. Storage policies protect church media.
- Public content and admin CRUD coexist in `App.tsx`; Music is reached through More.

## Migration state

All 12 active migrations are present locally and match the linked production ledger:

- 20260903000001_red_point_baseline.sql
- 20260903000002_red_point_admin_rls_fix.sql
- 20260904000001_production_backend.sql
- 20260904000002_sermon_audio_source.sql
- 20260904000003_table_grants.sql
- 20260905000001_event_time_integrity.sql
- 20260905000002_visitor_rate_limit.sql
- 20260905000003_music_foundation.sql
- 20260905000004_music_operating_layers.sql
- 20260905000005_music_operational_audit.sql
- 20260905000006_music_band_and_device_ownership.sql
- 20260905000007_music_band_leader_integrity.sql

Current migration status: BLOCKED. The linked remote ledger contains remote-only version `20260905184016`, which has no local SQL file. `npx supabase db push --dry-run` exits 1 on this mismatch. No repair/push/reset/pull/include-all was used.

## Music state

| Subsystem | State | Evidence |
|---|---|---|
| Profiles, roles, bands, memberships | PROVEN | deployed schema/RLS catalog checks |
| Services, assignments, confirmations | IMPLEMENTED/UNPROVEN E2E | code, deployed schema; no authorized full workflow run |
| Songs, setlists, resources | IMPLEMENTED/UNPROVEN E2E | deployed schema and Music UI; no real test scenario |
| Change history | PROVEN structurally | triggers and RLS catalog checks |
| Service-to-band relationship | PROVEN structurally | `music_services.band_id` deployed |
| Device token ownership | PROVEN structurally | `device_tokens.user_id`, register-device code |
| Targeted recipient resolution | IMPLEMENTED/UNPROVEN delivery | send-push resolves assignment IDs server-side |
| Band Leader uniqueness | PROVEN structurally | unique partial index migration |
| WhatsApp ingestion | BLOCKED | no webhook/inbound contract in repository |
| AI setlist/resource intelligence | NOT STARTED | no provider or contract |
| Real production Music workflow | UNPROVEN | no approved test account/data |

## Highest-value next task

`MUSIC-E2E-001`: prove the complete workflow with an authorized real test account, or record the exact human dependency if unavailable.
