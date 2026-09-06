-- Red Point Church
-- Migration: 20260905_table_grants
-- Purpose: Grant table access to anon and authenticated roles so RLS policies evaluate properly.
-- In PostgreSQL, table-level privileges are required before Row Level Security (RLS) policies are checked.

-- 1. Public-readable tables (RLS policies ensure anon only reads published = true)
grant select on public.events to anon, authenticated;
grant select on public.announcements to anon, authenticated;
grant select on public.sermons to anon, authenticated;
grant select on public.ministries to anon, authenticated;
grant select on public.leaders to anon, authenticated;
grant select on public.site_settings to anon, authenticated;

-- 2. Authenticated admin management (RLS policies ensure only public.is_admin() can write)
grant all on public.events to authenticated;
grant all on public.announcements to authenticated;
grant all on public.sermons to authenticated;
grant all on public.ministries to authenticated;
grant all on public.leaders to authenticated;
grant all on public.site_settings to authenticated;
grant all on public.visitor_submissions to authenticated;
grant all on public.device_tokens to authenticated;
grant all on public.notification_history to authenticated;
