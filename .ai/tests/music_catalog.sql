-- SELECT-only production catalog checks. Run through the approved Supabase read-only channel.
select table_name, exists (
  select 1 from information_schema.tables t
  where t.table_schema = 'public' and t.table_name = expected.table_name
) as present
from (values
  ('profiles'), ('music_roles'), ('bands'), ('band_memberships'),
  ('music_services'), ('service_assignments'), ('music_songs'),
  ('music_setlists'), ('music_setlist_items'), ('music_resources'),
  ('music_development'), ('music_change_history')
) expected(table_name)
order by table_name;

select tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename like 'music_%'
order by tablename, policyname;
