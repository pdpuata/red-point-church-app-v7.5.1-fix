# Known Limitations

- No WhatsApp/Make inbound webhook contract exists in the repository.
- No AI provider or credentials are configured.
- No approved production Music test account/data exists for full E2E proof.
- Linked Supabase migration ledger has remote-only `20260905184016`; dry-run is blocked until its provenance is reconciled safely.
- Notification recipient resolution is implemented, but automatic orchestration and delivery are not proven end-to-end.
- Music UI remains concentrated in `App.tsx`.
- `npm run typecheck` and Android export prove compilation/bundling, not complete operational correctness.
