# PROJECT CONTEXT — Red Point Church App

> Purpose and product context. Read this before any architectural work.

## What this is

The Red Point Church app is the church's own mobile application for **Red Point Church** (Pinetown / Ashley, KwaZulu-Natal, South Africa). It gives the congregation and visitors a single, trusted place on their phones for everything the church publishes: what's on, the latest message, how to visit, and how to get connected.

It is a **custom church platform**, not a generic template. It exists so the church controls its own content, branding, and communication rather than depending on Facebook, WhatsApp broadcast lists, or a website that people have to remember to visit.

## Who it is for

- **Congregation members** — see what's happening, listen to or watch the latest sermon, receive important updates.
- **First-time / new visitors** — a dedicated "New here?" path that removes the anxiety of a first Sunday and gives them a way to introduce themselves (visitor form → staff follow-up).
- **Church staff / admin** — an in-app staff area to create, review, publish and notify without touching code.

## Why it exists

Churches communicate constantly but across too many channels. The app exists to:

1. Give members **one reliable place** to check before Sunday.
2. Make the **latest sermon the easiest thing to find** — teaching is central to the church's life.
3. Let staff **publish and notify without a developer**.
4. Provide **direct push communication** that the church owns.

## Major user-facing goals

- **Home** — instantly answer "what's the latest message / update / this Sunday / I'm new."
- **Events** — what's coming up, with directions.
- **Sermons** — search and listen to / watch past messages.
- **Announcements** — important, time-bound church updates.
- **Ministries / Leadership / Contact** — how to get involved and who to reach.
- **More** — notifications, privacy, and the staff/admin entry.

## Why sermons are strategically important

Preaching is the primary content the church produces every week. The sermon library is therefore the app's **most valuable and most frequently refreshed content**. Reliable sermon delivery is the difference between an app people open weekly and one they abandon.

## Why the Home screen prioritizes the latest sermon

The Home screen ordering is a **deliberate product decision requested by church leadership**:

1. **Latest sermon** (primary)
2. **Latest announcement / update**
3. **This Sunday**
4. **"New here?"**

This is intentional and should be preserved unless leadership changes it. See `DECISIONS.md` (Decision 004).

## Reliability as a feature

The church's credibility depends on the app showing **correct, current** information. The product philosophy is therefore:

> **A maintainable church platform, not a collection of screens.**

That means reliability, data integrity, and safe publishing outrank visual novelty. Content defaults to **draft → review → publish** so nothing reaches the public app half-finished. When information cannot be loaded, the app says so rather than showing stale or invented content.
