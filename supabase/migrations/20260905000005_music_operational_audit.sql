-- Extend focused Music change history to the original operational tables.
-- This migration is additive and preserves existing RLS and data.

drop trigger if exists music_services_record_change on public.music_services;
create trigger music_services_record_change
  after insert or update or delete on public.music_services
  for each row execute function public.record_music_change();

drop trigger if exists service_assignments_record_change on public.service_assignments;
create trigger service_assignments_record_change
  after insert or update or delete on public.service_assignments
  for each row execute function public.record_music_change();

drop trigger if exists band_memberships_record_change on public.band_memberships;
create trigger band_memberships_record_change
  after insert or update or delete on public.band_memberships
  for each row execute function public.record_music_change();
