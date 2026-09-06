# Production Readiness

A workflow is production-ready only when it is:

- FUNCTIONAL: intended operation completes.
- SECURE: unauthorized actors are denied by database/server boundaries.
- PERSISTENT: reload preserves state.
- OBSERVABLE: important mutations leave useful evidence.
- RECOVERABLE: known failures have safe recovery.
- TESTED: acceptance criteria have reproducible evidence.

Compilation alone is none of these except a build signal.
