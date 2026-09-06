-- Store sermon audio hosted outside YouTube, such as the church's Squarespace archive.
alter table public.sermons add column if not exists audio_url text;
create unique index if not exists sermons_audio_url_unique_idx
	on public.sermons (audio_url)
	where audio_url is not null;
