# Task Backlog

## P0

### MUSIC-E2E-001
TITLE: Prove complete Music operational loop
STATUS: BLOCKED
PRIORITY: P0
AREA: Music
OWNER: AI
DEPENDENCIES: Authorized Music Leader, musician test accounts, approved test data
ACCEPTANCE: Band -> service -> band assignment -> individual assignment -> song -> setlist -> resource -> publish -> musician visibility -> confirmation -> Sunday Mode -> change history -> targeted recipient resolution.
VERIFICATION: `.ai/evidence/MUSIC-E2E-001.md`, production catalog, authorized UI path, persisted refresh.
EVIDENCE: `.ai/evidence/MUSIC-E2E-001.md`
BLOCKERS: No approved real test scenario; migration dry-run is also blocked by remote-only `20260905184016`.
NEXT: Resolve the remote migration provenance safely, then obtain authorized test account/data.

### MUSIC-NOTIFY-001
TITLE: Notification orchestration
STATUS: IMPLEMENTED/UNPROVEN
PRIORITY: P0
AREA: Music
OWNER: AI
DEPENDENCIES: E2E data and delivery-capable devices
ACCEPTANCE: assignment created/changed/removed and published setlist changes resolve owned recipient tokens server-side, record history, avoid duplicates, and fail observably.
VERIFICATION: authorized integration test plus Edge Function evidence.
EVIDENCE: pending.
BLOCKERS: automatic event orchestration and live delivery proof.
NEXT: implement/verify mutation-triggered orchestration.

### ADMIN-E2E-001
TITLE: Admin operational verification
STATUS: UNPROVEN
PRIORITY: P0
AREA: Admin
OWNER: AI
DEPENDENCIES: authorized admin account
ACCEPTANCE: content CRUD, storage, notifications, and RLS boundaries work through the existing Admin path.
VERIFICATION: authorized UI test and catalog evidence.
EVIDENCE: pending.
BLOCKERS: no approved test account in repository.
NEXT: run controlled admin test.

## P1

- MUSIC-WHATSAPP-001 — WhatsApp inbound contract — BLOCKED: no webhook/sender contract.
- MUSIC-AI-001 — AI setlist interpretation — BLOCKED: no provider/credentials/contract.
- MUSIC-AI-002 — AI resource intelligence — BLOCKED: no provider/contract; avoid fabricated resources.
- MUSIC-TEST-001 — Automated database/RLS tests — UNPROVEN: no existing test harness.
- MUSIC-UX-001 — Resilience/error-state pass — PARTIAL: existing states need controlled user-path testing.

## P2

- MUSIC-ANALYTICS-001 — Operational analytics — NOT STARTED.
- MUSIC-TRAINING-001 — Development/training expansion — PARTIAL foundation exists.
