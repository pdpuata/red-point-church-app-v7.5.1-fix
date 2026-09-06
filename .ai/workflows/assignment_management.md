# Assignment Management

WORKFLOW ID: MUSIC-ASSIGN-001
ACTOR: Music Leader/global admin
PRECONDITIONS: service and eligible roster
TRIGGER: add/remove/change responsibility
STEPS: choose service -> add eligible member -> set responsibility -> review confirmation -> save
DATABASE MUTATIONS: service_assignments
SIDE EFFECTS: change history; future targeted notification
NOTIFICATIONS: future assignment/changed/removed events
SECURITY BOUNDARY: service-scoped Music Leader RLS; musicians self-confirm only
SUCCESS STATE: assignment is visible to correct musician
FAILURE STATES: duplicate assignment, unauthorized mutation, stale service
ROLLBACK/RECOVERY: retry or re-read service detail
OBSERVABILITY: audit row and readiness count
TESTS: user A cannot mutate user B; musician protected-field deny
EVIDENCE: MUSIC-E2E-001
