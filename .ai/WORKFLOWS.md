# Workflows

## State machine

DISCOVERED -> SPECIFIED -> IMPLEMENTING -> IMPLEMENTED -> DATABASE_VERIFIED -> SECURITY_VERIFIED -> INTEGRATION_VERIFIED -> USER_PATH_VERIFIED -> PROVEN -> RELEASE_READY.

Alternates: BLOCKED, UNPROVEN, REJECTED, REGRESSION, NEEDS_HUMAN_INPUT.

A compile or export pass never promotes a task directly to PROVEN.

## Operational workflows

See `templates/workflow.md`. Every workflow must define actor, preconditions, database mutations, side effects, security boundary, failure states, recovery, and evidence.

## Approval boundaries

Music Leader explicitly publishes services/setlists. Future WhatsApp/AI interpretation may create drafts and suggestions only. Human review is mandatory before publication.
