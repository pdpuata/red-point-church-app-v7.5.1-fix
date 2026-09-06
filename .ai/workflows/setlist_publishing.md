# Setlist Publishing

WORKFLOW ID: MUSIC-SETLIST-PUBLISH-001
ACTOR: Music Leader/global admin
PRECONDITIONS: reviewed draft setlist
TRIGGER: explicit publish action
STEPS: inspect readiness -> publish -> reload -> verify assigned musician visibility
DATABASE MUTATIONS: music_setlists.status
SIDE EFFECTS: change history; future notification orchestration
NOTIFICATIONS: future setlist-published event
SECURITY BOUNDARY: Music Leader only; AI/import cannot publish
SUCCESS STATE: published setlist visible only to relevant assigned users
FAILURE STATES: missing songs/resources, permission error
ROLLBACK/RECOVERY: authorized unpublish/edit policy must be explicit; otherwise create corrective change
OBSERVABILITY: audit history
TESTS: musician publish deny; draft visibility deny
EVIDENCE: MUSIC-E2E-001
