# Database

## Canonical source

Use `supabase/migrations/`. Never rewrite historical migrations or use `--include-all`, reset, or pull to overwrite local state.

## Music tables

Foundation: `profiles`, `music_roles`, `bands`, `band_memberships`, `music_services`, `service_assignments`.

Operating layers: `music_songs`, `music_setlists`, `music_setlist_items`, `music_resources`, `music_development`, `music_change_history`.

Operational additions: `music_services.band_id`, `device_tokens.user_id`, one-leader partial unique index.

## Verification commands

```powershell
npx supabase migration list
npx supabase db push --dry-run
npx supabase db query --linked "select ..."
```

Use SELECT-only catalog queries for production inspection. A migration must be additive, dry-run clean, reviewed for destructive SQL, deployed only when the dry-run contains the intended migration, then verified by migration list, dry-run, schema, RLS, policies, grants, functions, and triggers.
