# Musician Assignment Confirmation

WORKFLOW ID: MUSIC-CONFIRM-001
ACTOR: authenticated musician
PRECONDITIONS: active assignment owned by auth.uid()
TRIGGER: Confirm or decline in Music
STEPS: load own assignment -> choose status -> update confirmation_status -> refresh
DATABASE MUTATIONS: service_assignments confirmation_status only
SIDE EFFECTS: change-history trigger; future targeted notification orchestration
NOTIFICATIONS: future assignment/confirmation event
SECURITY BOUNDARY: RLS and protect_self_assignment_update; user_id/service_id/responsibility/status immutable to musician
SUCCESS STATE: persisted confirmed/declined status
FAILURE STATES: query/update error, stale assignment, permission denied
ROLLBACK/RECOVERY: retry; reload current server state
OBSERVABILITY: updated_at and change history
TESTS: own allow; other-user deny; anonymous deny; protected-field deny
EVIDENCE: `.ai/evidence/MUSIC-E2E-001.md`
