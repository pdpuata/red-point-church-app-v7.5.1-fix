# Resource Management

WORKFLOW ID: MUSIC-RESOURCE-001
ACTOR: Music Leader/global admin
PRECONDITIONS: song/service context and legitimate link/upload
TRIGGER: add/edit/deactivate resource
STEPS: choose context -> enter verified resource reference -> save -> assigned musician reads it
DATABASE MUTATIONS: music_resources
SIDE EFFECTS: change history
NOTIFICATIONS: future resource-available event
SECURITY BOUNDARY: Music Leader write; assigned users read relevant active resources; no copyrighted scraping
SUCCESS STATE: preparation resource is explicit and reachable
FAILURE STATES: missing target/content, invalid link, permission error
ROLLBACK/RECOVERY: deactivate resource and replace link
OBSERVABILITY: active state and audit row
TESTS: unrelated user read deny; anonymous write deny
EVIDENCE: task-specific record required
