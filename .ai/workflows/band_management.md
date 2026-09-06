# Band Management

WORKFLOW ID: MUSIC-BAND-001
ACTOR: Music Leader/global admin
PRECONDITIONS: Auth session and Music Leader authorization
TRIGGER: create, rename, archive, membership, leader action
STEPS: load bands -> mutate band/membership -> refresh -> retain historical services
DATABASE MUTATIONS: bands and band_memberships
SIDE EFFECTS: change history for audited membership operations
NOTIFICATIONS: none currently automatic
SECURITY BOUNDARY: Music Leader RLS; one-leader partial unique index; no anonymous writes
SUCCESS STATE: active roster reflects requested state
FAILURE STATES: duplicate membership, duplicate leader, permission error
ROLLBACK/RECOVERY: restore archived band; retry failed mutation
OBSERVABILITY: updated_at and change history
TESTS: musician deny; unrelated Band Leader deny; Music Leader allow
EVIDENCE: task-specific record required
