# MUSIC-E2E-001 Evidence

DATE: 2026-09-05
TASK: Prove complete Music operational loop
ENVIRONMENT: Expo/React Native workspace; linked Supabase production project; no approved Music test account/data
STATUS: UNPROVEN

## Commands

- `npm run typecheck` — PASS
- `npx expo export --platform android` — PASS
- `npx supabase migration list` — PASS; local and remote migration versions aligned
- `npx supabase db push --dry-run` — PASS; database up to date
- editor diagnostics — PASS for App.tsx/lib/music.ts and recent Edge Functions

## Database checks

Structurally verified across prior deployment evidence: Music tables, RLS, grants, predicates, assignment protection, change triggers, band_id, device-token ownership, and one-leader index. No live row-level workflow was executed in this evidence record.

## Security checks

Static/catalog evidence: anonymous Music grants absent; Music Leader policies govern writes; musician assignment updates are self-scoped; published setlists are the read boundary; device recipients are resolved server-side from assignment IDs.

## User path

Not executed. The repository has no approved real Music test account/data and no fake production data was created.

## Expected result

Authorized Music Leader creates/manages band and service, assigns musician, creates/publishes setlist/resource, musician sees only published relevant data, confirms, Sunday Mode displays, changes are recorded, targeted recipient resolution returns owned tokens.

## Actual result

Compilation, bundle, migration alignment, schema/security structure, and client path are implemented. Full operational E2E is not proven.

## Unproven items

Live UI persistence, real RLS allow/deny calls under separate users, notification delivery, and complete change-to-notification orchestration.

## Blocker

Human must provide or authorize a safe test account and test data scenario.
