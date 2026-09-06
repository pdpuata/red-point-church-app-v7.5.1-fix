# Security

## Rules

- RLS plus table grants enforce authorization; UI hiding is not security.
- Anonymous users have no Music write access.
- Musician writes are self-scoped and assignment-protected.
- Band Leaders are scoped to their bands.
- Music Leaders manage Music operations; they cannot modify `admin_users`.
- Global admin remains `is_admin()`.
- `SECURITY DEFINER` functions must pin `search_path = public, pg_temp`, revoke public execution, and grant only intended roles.
- Device ownership is derived server-side from the Auth bearer token.
- Targeted push recipients are derived from assignment IDs server-side, never arbitrary client user IDs.
- Service-role credentials are permitted only in Edge Functions, never `App.tsx`, `lib/`, or bundled client configuration.
- AI/import data must enter draft/review state and never bypass human publication.

## Required negative checks

Anonymous write denied; musician role/membership/service/setlist writes denied; user A cannot mutate user B; Band Leader cannot mutate unrelated bands; draft setlists are invisible; change history is not client-writable; arbitrary notification recipients rejected by design.
