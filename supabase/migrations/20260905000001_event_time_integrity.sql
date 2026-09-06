-- Prevent newly created or updated events from having an end time before their start time.
-- NOT VALID keeps deployment safe if an older database already contains a bad historical row;
-- PostgreSQL still enforces this constraint for all new and updated rows.
alter table public.events drop constraint if exists events_ends_at_after_start;
alter table public.events
  add constraint events_ends_at_after_start
  check (ends_at is null or ends_at >= starts_at) not valid;
