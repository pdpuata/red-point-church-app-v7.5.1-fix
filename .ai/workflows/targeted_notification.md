# Targeted Notification

WORKFLOW ID: MUSIC-NOTIFY-001
ACTOR: authorized backend event path
PRECONDITIONS: valid assignment IDs and owned authenticated device tokens
TRIGGER: meaningful assignment/setlist event
STEPS: server receives event -> resolves assignment user IDs -> selects owned active tokens -> sends -> records result
DATABASE MUTATIONS: notification_history; token last-seen updates through registration
SIDE EFFECTS: Expo delivery request
NOTIFICATIONS: targeted only; no arbitrary client recipient IDs
SECURITY BOUNDARY: Edge Function auth and server-side relationship resolution
SUCCESS STATE: delivery request and outcome observable
FAILURE STATES: no token, provider failure, duplicate event
ROLLBACK/RECOVERY: retry policy and history inspection
OBSERVABILITY: notification history and function logs
TESTS: unrelated recipient rejected; anonymous trigger rejected; owned recipient allowed
EVIDENCE: MUSIC-NOTIFY-001
