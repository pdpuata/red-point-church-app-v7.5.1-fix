# ROADMAP — Red Point Church App

> Staged. Reliability and architecture first; features last. Each item is tagged NOW / NEXT / LATER / NOT YET JUSTIFIED.

## PHASE 1 — Stabilize the current system

- Remove deprecated Squarespace ingestion references from scripts/docs/config. **NOW**
- Keep `docs/` (this layer) accurate as the system changes. **NOW**
- Resolve the `preacher` schema/code mismatch deliberately (define creator vs preacher first). **NOW**
- Preserve working YouTube ingestion; add a light ingestion result check (imported/updated counts surfaced in admin). **NEXT**
- Verify admin security end-to-end on the live project (RLS + Edge + non-admin cannot write). **NEXT**
- Add a server-side rate limit to `send-push`. **NEXT**

## PHASE 2 — Improve maintainability

- Gradually extract screens/components out of `App.tsx` as they are touched (no big-bang rewrite). **LATER**
- Introduce a clearer navigation approach only if deep-linking/gesture needs outgrow the state machine. **LATER**
- Introduce a thin data-access layer for repeated `supabase.from` patterns. **LATER**
- Strengthen shared types / domain models; reduce duplicated logic. **LATER**

## PHASE 3 — Strengthen the content platform

- Deliberate sermon-ingestion abstraction (a `SermonSource` interface) so new sources plug in cleanly. **LATER**
- Podcast/RSS as an *optional* future source behind that abstraction. **LATER**
- Source normalization + deduplication rules per source. **LATER**
- Ingestion monitoring/logging surfaced to admins. **LATER**
- Richer content-health diagnostics. **LATER**

## PHASE 4 — Product expansion (only if strategically justified)

- Event RSVP / calendar subscription. **NOT YET JUSTIFIED**
- In-app Bible reading / notes. **NOT YET JUSTIFIED**
- Giving / donations integration. **NOT YET JUSTIFIED**
- Small-group finder with sign-up. **NOT YET JUSTIFIED**

> Guideline: do not over-engineer. A feature joins the roadmap only when it clearly serves members/visitors or reduces staff workload.
