# Architectural Decisions

## Source of truth

Decision: Red Point is authoritative Music state. WhatsApp/email/push are channels.

Why: delivery channels must not create conflicting operational truth.

## AI approval

Decision: Future AI interpretation creates draft/suggestions only.

Why: Music Leader approval is the publication boundary.

## Targeted notifications

Decision: resolve recipients server-side from authorized assignments and owned device tokens.

Why: arbitrary client recipient IDs create an authorization risk.

## Archived bands

Decision: archive/deactivate rather than delete; historical services retain relationships.

Why: lifecycle management must preserve operational history.

## Minimal architecture

Decision: retain `App.tsx`, Supabase client, migrations, RLS, and Edge Functions.

Why: incremental change reduces regression and migration risk.
