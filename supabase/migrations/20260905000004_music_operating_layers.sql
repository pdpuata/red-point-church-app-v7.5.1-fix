-- Red Point Church Music operating layers.
-- Extends the deployed Music Foundation without changing existing migrations.

create table if not exists public.music_songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist text,
  active boolean not null default true,
  default_key text,
  bpm integer check (bpm is null or bpm > 0),
  ccli_reference text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint music_songs_title_not_blank check (length(btrim(title)) > 0)
);

create table if not exists public.music_setlists (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null unique references public.music_services(id) on delete cascade,
  status text not null default 'draft' check (status in ('draft', 'published')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.music_setlist_items (
  id uuid primary key default gen_random_uuid(),
  setlist_id uuid not null references public.music_setlists(id) on delete cascade,
  song_id uuid not null references public.music_songs(id) on delete restrict,
  position integer not null check (position > 0),
  key_override text,
  arrangement text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (setlist_id, position),
  unique (setlist_id, song_id)
);

create table if not exists public.music_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  resource_type text not null check (resource_type in ('audio', 'chart', 'lyrics', 'link', 'note')),
  url text,
  body text,
  song_id uuid references public.music_songs(id) on delete cascade,
  service_id uuid references public.music_services(id) on delete cascade,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint music_resources_title_not_blank check (length(btrim(title)) > 0),
  constraint music_resources_target_check check (song_id is not null or service_id is not null),
  constraint music_resources_content_check check (url is not null or body is not null)
);

create table if not exists public.music_development (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  status text not null default 'trainee' check (status in ('trainee', 'developing', 'competent', 'leader_ready')),
  skill text,
  mentor_user_id uuid references public.profiles(user_id) on delete set null,
  notes text,
  updated_at timestamptz not null default now()
);

create table if not exists public.music_change_history (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles(user_id) on delete set null,
  entity_type text not null,
  entity_id uuid not null,
  action text not null check (action in ('insert', 'update', 'delete')),
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create index if not exists music_songs_active_title_idx on public.music_songs (active, title);
create index if not exists music_setlist_items_order_idx on public.music_setlist_items (setlist_id, position);
create index if not exists music_resources_song_idx on public.music_resources (song_id, active);
create index if not exists music_resources_service_idx on public.music_resources (service_id, active);
create index if not exists music_change_history_entity_idx on public.music_change_history (entity_type, entity_id, created_at desc);

drop trigger if exists music_songs_set_updated_at on public.music_songs;
create trigger music_songs_set_updated_at before update on public.music_songs for each row execute function public.set_updated_at();
drop trigger if exists music_setlists_set_updated_at on public.music_setlists;
create trigger music_setlists_set_updated_at before update on public.music_setlists for each row execute function public.set_updated_at();
drop trigger if exists music_setlist_items_set_updated_at on public.music_setlist_items;
create trigger music_setlist_items_set_updated_at before update on public.music_setlist_items for each row execute function public.set_updated_at();
drop trigger if exists music_resources_set_updated_at on public.music_resources;
create trigger music_resources_set_updated_at before update on public.music_resources for each row execute function public.set_updated_at();
drop trigger if exists music_development_set_updated_at on public.music_development;
create trigger music_development_set_updated_at before update on public.music_development for each row execute function public.set_updated_at();

create or replace function public.record_music_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.music_change_history (actor_user_id, entity_type, entity_id, action, before_data, after_data)
  values (
    auth.uid(),
    tg_table_name,
    coalesce(new.id, old.id),
    lower(tg_op),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists music_songs_record_change on public.music_songs;
create trigger music_songs_record_change after insert or update or delete on public.music_songs for each row execute function public.record_music_change();
drop trigger if exists music_setlists_record_change on public.music_setlists;
create trigger music_setlists_record_change after insert or update or delete on public.music_setlists for each row execute function public.record_music_change();
drop trigger if exists music_setlist_items_record_change on public.music_setlist_items;
create trigger music_setlist_items_record_change after insert or update or delete on public.music_setlist_items for each row execute function public.record_music_change();
drop trigger if exists music_resources_record_change on public.music_resources;
create trigger music_resources_record_change after insert or update or delete on public.music_resources for each row execute function public.record_music_change();

alter table public.music_songs enable row level security;
alter table public.music_setlists enable row level security;
alter table public.music_setlist_items enable row level security;
alter table public.music_resources enable row level security;
alter table public.music_development enable row level security;
alter table public.music_change_history enable row level security;

create policy "Music users read relevant songs" on public.music_songs for select to authenticated using (
  public.is_music_leader() or exists (
    select 1 from public.music_setlist_items item
    join public.music_setlists list on list.id = item.setlist_id
    join public.service_assignments assignment on assignment.service_id = list.service_id
    where item.song_id = music_songs.id and assignment.user_id = auth.uid() and list.status = 'published'
  )
);
create policy "Music leaders manage songs" on public.music_songs for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

create policy "Users read relevant setlists" on public.music_setlists for select to authenticated using (
  public.is_music_leader() or exists (
    select 1 from public.service_assignments assignment
    where assignment.service_id = music_setlists.service_id and assignment.user_id = auth.uid() and music_setlists.status = 'published'
  )
);
create policy "Music leaders manage setlists" on public.music_setlists for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

create policy "Users read relevant setlist items" on public.music_setlist_items for select to authenticated using (
  public.is_music_leader() or exists (
    select 1 from public.music_setlists list
    join public.service_assignments assignment on assignment.service_id = list.service_id
    where list.id = music_setlist_items.setlist_id and assignment.user_id = auth.uid() and list.status = 'published'
  )
);
create policy "Music leaders manage setlist items" on public.music_setlist_items for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

create policy "Users read relevant resources" on public.music_resources for select to authenticated using (
  public.is_music_leader() or (
    (service_id is not null and exists (select 1 from public.service_assignments where service_id = music_resources.service_id and user_id = auth.uid()))
    or (song_id is not null and exists (
      select 1 from public.music_setlist_items item
      join public.music_setlists list on list.id = item.setlist_id
      join public.service_assignments assignment on assignment.service_id = list.service_id
      where item.song_id = music_resources.song_id and assignment.user_id = auth.uid() and list.status = 'published'
    ))
  )
);
create policy "Music leaders manage resources" on public.music_resources for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

create policy "Users read own development" on public.music_development for select to authenticated using (user_id = auth.uid() or public.is_music_leader());
create policy "Users update own development" on public.music_development for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Music leaders manage development" on public.music_development for all to authenticated using (public.is_music_leader()) with check (public.is_music_leader());

create policy "Music leaders read change history" on public.music_change_history for select to authenticated using (public.is_music_leader());

revoke all on public.music_songs, public.music_setlists, public.music_setlist_items, public.music_resources, public.music_development, public.music_change_history from anon;
grant select on public.music_songs, public.music_setlists, public.music_setlist_items, public.music_resources, public.music_development to authenticated;
grant insert, update, delete on public.music_songs, public.music_setlists, public.music_setlist_items, public.music_resources to authenticated;
grant update on public.music_development to authenticated;
revoke all on function public.record_music_change() from public;