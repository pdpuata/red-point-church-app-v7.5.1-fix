# Setlist Creation

WORKFLOW ID: MUSIC-SETLIST-001
ACTOR: Music Leader/global admin
PRECONDITIONS: service exists
TRIGGER: add/remove/reorder/edit item
STEPS: select service -> create/select setlist -> add canonical songs -> edit service-specific item -> keep draft
DATABASE MUTATIONS: music_setlists, music_setlist_items
SIDE EFFECTS: change history
NOTIFICATIONS: none until publish
SECURITY BOUNDARY: Music Leader write; draft hidden from assigned musicians
SUCCESS STATE: deterministic running order
FAILURE STATES: duplicate position/song, stale setlist, permission error
ROLLBACK/RECOVERY: temporary position for reorder; reload setlist
OBSERVABILITY: audit rows
TESTS: musician cannot write/read draft
EVIDENCE: MUSIC-E2E-001
