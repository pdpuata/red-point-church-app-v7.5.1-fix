-- Red Point Church
-- Migration: 20260905_000003_reconcile_missing_production_changes
-- Purpose:
--   Reconcile two schema changes that exist locally but were confirmed
--   missing from the production database:
--     1. Event start/end validation
--     2. Visitor submission rate limiting
--
-- IMPORTANT:
--   Table grants and sermons.audio_url were verified separately as already
--   existing in production and are intentionally NOT included here.

-- ============================================================
-- 1. Prevent events from ending before they start
-- ============================================================

alter table public.events
  drop constraint if exists events_ends_at_after_start;

alter table public.events
  add constraint events_ends_at_after_start
  check (ends_at is null or ends_at >= starts_at)
  not valid;


-- ============================================================
-- 2. Visitor submission rate limiting
-- ============================================================

create table if not exists public.visitor_rate_limits (
  key text primary key,
  window_start timestamptz not null,
  count integer not null,
  expires_at timestamptz not null
);

create index if not exists visitor_rate_limits_expires_idx
  on public.visitor_rate_limits (expires_at);

alter table public.visitor_rate_limits enable row level security;


create or replace function public.check_visitor_rate(
  p_key text,
  p_max int,
  p_window_seconds int
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := now();
  v_window interval := make_interval(
    secs => greatest(p_window_seconds, 1)
  );
  v_count integer;
begin
  delete from public.visitor_rate_limits
  where expires_at < v_now;

  insert into public.visitor_rate_limits (
    key,
    window_start,
    count,
    expires_at
  )
  values (
    p_key,
    v_now,
    1,
    v_now + v_window
  )
  on conflict (key) do update
    set count = case
      when public.visitor_rate_limits.window_start + v_window <= v_now
      then 1
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


-- The rate-limit state and function must not be callable
-- by anonymous or authenticated clients.

revoke all
  on function public.check_visitor_rate(text, int, int)
  from public;

revoke all
  on function public.check_visitor_rate(text, int, int)
  from anon;

revoke all
  on function public.check_visitor_rate(text, int, int)
  from authenticated;

grant execute
  on function public.check_visitor_rate(text, int, int)
  to service_role;