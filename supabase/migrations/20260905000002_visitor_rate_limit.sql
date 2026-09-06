-- Red Point Church
-- Migration: 20260905_visitor_rate_limit
-- Purpose: server-side, per-client-IP rate limiting for the public submit-visitor
--          Edge Function, to reduce automated submission / email abuse.
--
-- Design notes:
--   * First layer only: 3 submissions per 10-minute window per client key.
--   * State is internal server-side. The table is NOT readable or writable by
--     anon or authenticated clients (RLS enabled, no policies, no grants), the
--     same pattern that already protects public.admin_users.
--   * The decision is made atomically in a single UPSERT ... RETURNING, so two
--     concurrent requests from the same key cannot both pass by observing the
--     same previous count.
--   * Expired rows are removed opportunistically inside the same call, so the
--     table does not grow indefinitely. No scheduled job/cron is introduced.

-- Internal rate-limit state. Only the service role (Edge Functions) may access it.
create table if not exists public.visitor_rate_limits (
  key text primary key,
  window_start timestamptz not null,
  count integer not null,
  expires_at timestamptz not null
);

-- Index to keep opportunistic cleanup cheap.
create index if not exists visitor_rate_limits_expires_idx
  on public.visitor_rate_limits (expires_at);

-- Lock the table down: enable RLS and deliberately create NO policies, so
-- anon/authenticated can do nothing. No table-level GRANT is issued for it.
alter table public.visitor_rate_limits enable row level security;

-- Atomic check-and-increment.
-- Returns the request's count within the CURRENT window for the given key
-- (1 = first request of a fresh window). The caller compares this to the limit.
-- SECURITY DEFINER so it can run against the locked-down table when invoked by
-- the service-role Edge Function. search_path is pinned; only the specific
-- arguments needed are accepted, so it is not a general-purpose SQL interface.
create or replace function public.check_visitor_rate(p_key text, p_max int, p_window_seconds int)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := now();
  v_window interval := make_interval(secs => greatest(p_window_seconds, 1));
  v_count integer;
begin
  -- Opportunistic, bounded cleanup of expired state (table stays small).
  delete from public.visitor_rate_limits where expires_at < v_now;

  insert into public.visitor_rate_limits (key, window_start, count, expires_at)
  values (p_key, v_now, 1, v_now + v_window)
  on conflict (key) do update
    set count = case
                  when public.visitor_rate_limits.window_start + v_window <= v_now
                  then 1                                  -- window expired -> start fresh
                  else public.visitor_rate_limits.count + 1
                end,
        window_start = case
                  when public.visitor_rate_limits.window_start + v_window <= v_now
                  then v_now
                  else public.visitor_rate_limits.window_start
                end,
        expires_at = case
                  when public.visitor_rate_limits.window_start + v_window <= v_now
                  then v_now + v_window
                  else public.visitor_rate_limits.window_start + v_window
                end
  returning count into v_count;

  return v_count;
end;
$$;

-- The function is only a server-side helper, not a public API.
revoke all on function public.check_visitor_rate(text, int, int) from public;
revoke all on function public.check_visitor_rate(text, int, int) from anon;
revoke all on function public.check_visitor_rate(text, int, int) from authenticated;
grant execute on function public.check_visitor_rate(text, int, int) to service_role;
