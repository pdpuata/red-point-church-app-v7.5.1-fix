# Sunday Execution

WORKFLOW ID: MUSIC-SUNDAY-001
ACTOR: musician, Band Leader, Music Leader
PRECONDITIONS: today's relevant service and published setlist
TRIGGER: open Sunday Mode
STEPS: read service -> responsibility -> running order -> key/BPM/notes/resources -> respond if needed
DATABASE MUTATIONS: none for read-only execution; confirmation remains separate
SIDE EFFECTS: none required
NOTIFICATIONS: future reminder/last-minute events
SECURITY BOUNDARY: assigned user or authorized Music role
SUCCESS STATE: user has current execution information without editing configuration
FAILURE STATES: no service, stale data, missing setlist/resource
ROLLBACK/RECOVERY: refresh and show stale/error state
OBSERVABILITY: read path and existing changes
TESTS: assigned visibility allow; unrelated visibility deny
EVIDENCE: MUSIC-E2E-001
