-- Keep band leadership unambiguous while preserving the separate role/scope model.

create unique index if not exists band_memberships_one_leader_idx
  on public.band_memberships (band_id)
  where is_leader;
