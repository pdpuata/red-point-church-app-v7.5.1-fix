# Testing

## Standard regression

```powershell
npm run typecheck
npx expo export --platform android
npx supabase migration list
npx supabase db push --dry-run
```

## Static scans

Scan client files for `service_role`, `SUPABASE_SERVICE_ROLE`, and `SERVICE_ROLE_KEY`. Scan new migrations for `DROP TABLE`, `TRUNCATE`, `DELETE FROM`, RLS disabling, unexpected grants, and duplicate versions.

## Evidence standard

Record command, exit code, scope, expected result, actual result, and unproven items under `.ai/evidence/`. Do not call catalog presence proof of a complete user workflow.

## Production tests

Use only authorized real accounts and approved test data. Never fabricate Auth users or bypass RLS. If credentials/account/data are missing, mark the workflow UNPROVEN/BLOCKED and state the exact human dependency.
