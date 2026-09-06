-- Red Point Church
-- Migration: 20260906_sermon_source_guid
-- Purpose: retain the canonical external identifier for RSS sermon episodes.
-- Existing sermon rows remain unchanged; source_guid is nullable for legacy/manual rows.

alter table public.sermons
  add column if not exists source_guid text;

create unique index if not exists sermons_source_guid_unique_idx
  on public.sermons (source_guid)
  where source_guid is not null;
