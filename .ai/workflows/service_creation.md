# Service Creation

WORKFLOW ID: MUSIC-SERVICE-001
ACTOR: Music Leader/global admin
PRECONDITIONS: active serving band and valid times
TRIGGER: create/edit/publish service
STEPS: select active band -> enter service -> assign members -> save draft or publish -> inspect readiness
DATABASE MUTATIONS: music_services, service_assignments, music_setlists
SIDE EFFECTS: updated_at and operational change history
NOTIFICATIONS: future assignment/publish orchestration
SECURITY BOUNDARY: Music Leader RLS; archived bands excluded by UI and should be denied by service policy/validation
SUCCESS STATE: service persists with band and assignments
FAILURE STATES: invalid time, missing band, duplicate assignment, permission error
ROLLBACK/RECOVERY: retain draft; retry failed child mutation; inspect partial state
OBSERVABILITY: readiness and change history
TESTS: Musician deny; Music Leader allow; persisted reload
EVIDENCE: MUSIC-E2E-001
