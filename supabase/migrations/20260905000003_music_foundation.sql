-- Red Point Church
-- Migration: 20260905_000004_music_foundation
-- Purpose: establish the Music operating foundation without changing global admin auth.

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  email text,
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.music_roles (
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  role text not null check (role in ('musician', 'band_leader', 'music_leader')),
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

create table if not exists public.bands (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bands_name_not_blank check (length(btrim(name)) > 0)
);

create table if not exists public.band_memberships (
  band_id uuid not null references public.bands(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  is_leader boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (band_id, user_id)
);

create table if not exists public.music_services (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  service_date date not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  service_type text not null default 'sunday',
  status text not null default 'scheduled' check (status in ('draft', 'scheduled', 'cancelled', 'completed')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint music_services_title_not_blank check (length(btrim(title)) > 0),
  constraint music_services_ends_after_start check (ends_at is null or ends_at >= starts_at)
);

create table if not exists public.service_assignments (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.music_services(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete restrict,
  responsibility text not null,
  assignment_status text not null default 'active' check (assignment_status in ('draft', 'active', 'cancelled')),
  confirmation_status text not null default 'pending' check (confirmation_status in ('pending', 'confirmed', 'declined')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_assignments_responsibility_not_blank check (length(btrim(responsibility)) > 0),
  unique (service_id, user_id, responsibility)
);

create index if not exists music_roles_role_idx on public.music_roles (role, user_id);
create index if not exists band_memberships_user_idx on public.band_memberships (user_id, band_id);
create index if not exists band_memberships_leaders_idx on public.band_memberships (band_id, user_id) where is_leader;
create index if not exists music_services_schedule_idx on public.music_services (service_date, starts_at);
create index if not exists service_assignments_user_idx on public.service_assignments (user_id, service_id);
create index if not exists service_assignments_service_idx on public.service_assignments (service_id, confirmation_status);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists bands_set_updated_at on public.bands;
create trigger bands_set_updated_at before update on public.bands for each row execute function public.set_updated_at();
drop trigger if exists music_services_set_updated_at on public.music_services;
create trigger music_services_set_updated_at before update on public.music_services for each row execute function public.set_updated_at();
drop trigger if exists service_assignments_set_updated_at on public.service_assignments;
create trigger service_assignments_set_updated_at before update on public.service_assignments for each row execute function public.set_updated_at();

create or replace function public.handle_new_music_profile()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (user_id, display_name, email)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''), nullif(btrim(new.raw_user_meta_data ->> 'name'), ''), ''),
    new.email
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_music_profile on auth.users;
create trigger on_auth_user_created_music_profile
  after insert on auth.users
  for each row execute function public.handle_new_music_profile();

insert into public.profiles (user_id, display_name, email)
select id, coalesce(nullif(btrim(raw_user_meta_data ->> 'full_name'), ''), nullif(btrim(raw_user_meta_data ->> 'name'), ''), ''), email
from auth.users
on conflict (user_id) do nothing;

create or replace function public.is_music_leader()
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select public.is_admin()
    or exists (
      select 1 from public.music_roles
      where user_id = auth.uid() and role = 'music_leader'
    );
$$;

create or replace function public.is_band_leader_of(target_band_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select public.is_music_leader()
    or (
      exists (select 1 from public.music_roles where user_id = auth.uid() and role = 'band_leader')
      and exists (
        select 1 from public.band_memberships
        where band_id = target_band_id and user_id = auth.uid() and is_leader
      )
    );
$$;

create or replace function public.is_band_member_of(target_band_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.band_memberships
    where band_id = target_band_id and user_id = auth.uid()
  );
$$;

create or replace function public.protect_self_assignment_update()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() = old.user_id and not public.is_music_leader() then
    if new.service_id <> old.service_id
      or new.user_id <> old.user_id
      or new.responsibility <> old.responsibility
      or new.assignment_status <> old.assignment_status then
      raise exception 'Musicians may only update their assignment confirmation and notes';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists service_assignments_protect_self_update on public.service_assignments;
create trigger service_assignments_protect_self_update
  before update on public.service_assignments
  for each row execute function public.protect_self_assignment_update();

alter table public.profiles enable row level security;
alter table public.music_roles enable row level security;
alter table public.bands enable row level security;
alter table public.band_memberships enable row level security;
alter table public.music_services enable row level security;
alter table public.service_assignments enable row level security;

drop policy if exists "Users read own profiles" on public.profiles;
create policy "Users read own profiles" on public.profiles for select to authenticated using (user_id = auth.uid());
drop policy if exists "Music leaders read profiles" on public.profiles;
create policy "Music leaders read profiles" on public.profiles for select to authenticated using (public.is_music_leader());
drop policy if exists "Band leaders read band member profiles" on public.profiles;
create policy "Band leaders read band member profiles" on public.profiles for select to authenticated using (
  exists (
    select 1
    from public.band_memberships member
    where member.user_id = profiles.user_id and public.is_band_leader_of(member.band_id)
  )
);
drop policy if exists "Users update own profiles" on public.profiles;
create policy "Users update own profiles" on public.profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "Music leaders update profiles" on public.profiles;
create policy "Music leaders update profiles" on public.profiles for update to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

drop policy if exists "Users read own music roles" on public.music_roles;
create policy "Users read own music roles" on public.music_roles for select to authenticated using (user_id = auth.uid());
drop policy if exists "Music leaders manage music roles" on public.music_roles;
create policy "Music leaders manage music roles" on public.music_roles for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

drop policy if exists "Members read their bands" on public.bands;
create policy "Members read their bands" on public.bands for select to authenticated using (
  public.is_music_leader() or exists (select 1 from public.band_memberships where band_id = bands.id and user_id = auth.uid())
);
drop policy if exists "Music leaders manage bands" on public.bands;
create policy "Music leaders manage bands" on public.bands for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

drop policy if exists "Members read band memberships" on public.band_memberships;
create policy "Members read band memberships" on public.band_memberships for select to authenticated using (
  user_id = auth.uid() or public.is_band_member_of(band_id) or public.is_band_leader_of(band_id)
);
drop policy if exists "Music leaders manage memberships" on public.band_memberships;
create policy "Music leaders manage memberships" on public.band_memberships for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

drop policy if exists "Users read relevant music services" on public.music_services;
create policy "Users read relevant music services" on public.music_services for select to authenticated using (
  public.is_music_leader() or exists (
    select 1 from public.service_assignments
    where service_id = music_services.id and user_id = auth.uid()
  )
);
drop policy if exists "Music leaders manage music services" on public.music_services;
create policy "Music leaders manage music services" on public.music_services for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

drop policy if exists "Users read relevant assignments" on public.service_assignments;
create policy "Users read relevant assignments" on public.service_assignments for select to authenticated using (
  user_id = auth.uid() or public.is_music_leader() or exists (
    select 1 from public.band_memberships member
    where member.user_id = service_assignments.user_id and public.is_band_leader_of(member.band_id)
  )
);
drop policy if exists "Users confirm own assignments" on public.service_assignments;
create policy "Users confirm own assignments" on public.service_assignments for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "Music leaders manage assignments" on public.service_assignments;
create policy "Music leaders manage assignments" on public.service_assignments for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

revoke all on public.profiles, public.music_roles, public.bands, public.band_memberships, public.music_services, public.service_assignments from anon;
grant select, update on public.profiles to authenticated;
grant select on public.music_roles, public.bands, public.band_memberships, public.music_services, public.service_assignments to authenticated;
grant insert, update, delete on public.music_roles, public.bands, public.band_memberships, public.music_services, public.service_assignments to authenticated;

revoke all on function public.handle_new_music_profile() from public;
revoke all on function public.is_music_leader() from public;
revoke all on function public.is_band_leader_of(uuid) from public;
revoke all on function public.is_band_member_of(uuid) from public;
revoke all on function public.protect_self_assignment_update() from public;
grant execute on function public.is_music_leader() to authenticated;
grant execute on function public.is_band_leader_of(uuid) to authenticated;
grant execute on function public.is_band_member_of(uuid) to authenticated;