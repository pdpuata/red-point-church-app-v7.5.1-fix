# Architecture

## Boundaries

- App: `App.tsx` owns navigation, screen state, auth reads, Music queries, mutations, and presentation.
- Domain types: `lib/music.ts`.
- Database: additive Supabase migrations; PostgreSQL constraints, grants, RLS, functions, and triggers.
- Functions: server-only privileged operations and external delivery.
- Notifications: device registration plus `send-push`; database remains source of truth.

## Music dependency graph

Auth user -> profile -> Music role -> band membership -> service -> assignment -> setlist -> song/resource -> publish -> confirmation -> change history -> notification delivery -> Sunday Mode.

## Authorization

Global admin is `admin_users`/`is_admin()`. Music Leader is a Music role; global admin inherits Music operational access through `is_music_leader()`, but Music roles never grant global admin. Band Leader scope requires role plus leader membership. Musicians can only confirm/decline their own assignment.

## Non-goals

No React Navigation rewrite, repository/state framework, WhatsApp clone, AI provider, automatic AI publication, or duplicate notification system.
