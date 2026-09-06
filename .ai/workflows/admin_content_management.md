# Admin Content Management

WORKFLOW ID: ADMIN-CONTENT-001
ACTOR: global admin
PRECONDITIONS: authenticated session and `is_admin()` membership
TRIGGER: existing Admin CRUD action
STEPS: sign in -> load content -> edit/create/publish -> verify public result
DATABASE MUTATIONS: existing public content tables/storage
SIDE EFFECTS: existing notification/storage behavior
NOTIFICATIONS: only through existing authenticated Edge Function path
SECURITY BOUNDARY: admin_users/is_admin plus RLS; no Music role inheritance back to admin
SUCCESS STATE: content persisted and public policy behavior correct
FAILURE STATES: unauthorized session, validation, storage/provider error
ROLLBACK/RECOVERY: existing draft/unpublish flows
OBSERVABILITY: existing content timestamps/notification history
TESTS: anonymous deny; authenticated non-admin deny; global admin allow
EVIDENCE: ADMIN-E2E-001
