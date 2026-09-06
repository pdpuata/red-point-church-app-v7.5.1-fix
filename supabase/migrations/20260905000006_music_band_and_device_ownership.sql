-- Persist the serving band and securely associate authenticated device tokens.

alter table public.music_services
  add column if not exists band_id uuid references public.bands(id) on delete set null;

create index if not exists music_services_band_schedule_idx
  on public.music_services (band_id, starts_at);

alter table public.device_tokens
  add column if not exists user_id uuid references auth.users(id) on delete cascade;

create index if not exists device_tokens_user_active_idx
  on public.device_tokens (user_id, active, last_seen_at desc);

alter table public.device_tokens enable row level security;

drop policy if exists "Users manage own device tokens" on public.device_tokens;
create policy "Users manage own device tokens"
  on public.device_tokens
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Admins manage all device tokens"
  on public.device_tokens
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());
