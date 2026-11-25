# Replay canvases — shared method + per-cohort specifics

Two pinned canvases in **#agent-teetsh** (`C0APLG0HB1T`) index PostHog session replays, one per cohort. Same write method for both.

## CRITICAL — Slack canvas API gotcha

`slack_update_canvas` **section-targeted `replace`/`append` silently drops following sibling sections** (a whitespace/empty replace corrupts the doc). Do NOT edit section-by-section.

**Reliable method:** one full-canvas `replace` with **no `section_id`**. Its real behavior: it **keeps the pre-existing first title node** and clears everything else. So:

- **Omit a leading `# H1`** in the replace content — the kept node supplies the title; including one creates a duplicate.
- Provide the complete body (intro + all tables + notes + last-update line) in that single call.
- **Always `slack_read_canvas` afterward** to verify exactly one H1 and all sections present.

## Shared row conventions

- Rows chronological by first session; one row per session/user as the cohort dictates.
- **Durée = minutes actives** (`active_seconds`) — never raw duration.
- `⏳` for `ongoing:true`; `(interne)` for `@teetsh.com` accounts; note console errors inline when > 0.
- Always end the canvas with `Dernière mise à jour : DD/MM/YYYY HH:MM`.

---

## Canvas 1 — "Import IA — enregistrements des sessions"

- Canvas file = `F0BFSQNJC3W` (`https://teetsh.slack.com/docs/T58D7UPHS/F0BFSQNJC3W`)
- Dashboard = **"AI Document Import" #789249** (`https://eu.posthog.com/project/1617/dashboard/789249`)
- GA date: **2026-07-07 ~14:10 Paris**. No flag / person property for this cohort (import flags removed at GA) — the cohort spine is **event-based**.

### Cohort spine

Replay auto-starts on wizard mount, so every wizard visit has a recording. Sessions are found via FE funnel events, prefixes `EdtImport` / `FdpImport` / `ProgImport` (steps `:opened`, `:documentSubmitted`, `:analyzed`, `:questionsSubmitted`, `:created`), plus backend `AiImport:analyzed|created` (has `kind` prop).

1. **Roster SQL** (authoritative; taxonomy may warn on `FdpImport:*` until the first FDP import fires — that's fine):
   `SELECT properties.$session_id AS session_id, any(person.properties.email) AS email, min(timestamp) AS first_ts, groupUniqArray(event) AS import_events FROM events WHERE timestamp >= '<last_update>' AND event IN (all 15 {Edt,Fdp,Prog}Import:* events) GROUP BY session_id ORDER BY first_ts ASC`
2. **Recordings**: `query-session-recordings-list` with `session_ids: [...]` from step 1 (NOT property filters). Gives `active_seconds`, `ongoing`, `console_error_count`.
3. Sessions with events but no recording = pre-replay-deploy staff sessions (keep in the "Avant la GA" section, don't grow it).

### Canvas format

- Columns: user email, type (EDT/Prog/FDP), heure, durée, **Parcours** = max funnel step reached (`ouvert seulement` / `document soumis` / `analysé` / `✅ créé`), replay link.
- One table per day while volume is low; switch to `## Semaine du …` sections when a table passes ~25 rows.
- On refresh, re-query since a day BEFORE the last update (ongoing sessions extend and funnel steps advance — re-pull existing ⏳ rows' session_ids too and update them).

### Analytics summary post (draft, never auto-send)

Compute for the period since the last post (SQL against `events`, unique users AND event counts):

1. **Funnel per kind**: users at `opened → documentSubmitted → analyzed → created` for `EdtImport` / `ProgImport` / `FdpImport`.
2. **Imports created**: `AiImport:created` count + `properties.kind` breakdown.
3. **% via IA**: `properties.source` breakdown of `EmploiDuTemps:created`, `Programmation:created`, `FicheDePrep:created` (FDP KPI unit = % of *fiches*, since one import creates N fiches). `Sequence:created` never fires for `fdp_standalone` wrappers.
4. Skim dashboard #789249 for anomalies (timing buckets, recurrence) worth a bullet.

Format per the SKILL.md Slack-posting convention; include dashboard + canvas links.

---

## Canvas 2 — "Onboarding agent — enregistrements des sessions"

- Canvas file = `F0BAS8K9U3Z` (search `creator:@Arnaud onboarding` in files if the ID ever changes)
- Cohort spine = person property **`onboarding_variant = agent`** (replay is always on for this cohort)
- The cohort grows in discrete **waves** (cap openings announced in #agent-teetsh), not continuously.

### Procedure

1. **Read current state.** `slack_read_canvas F0BAS8K9U3Z` — note "Dernière mise à jour" and the existing roster/waves.
2. **Check the channel for cap changes.** Skim recent #agent-teetsh messages/threads for an "ouverture" / "+N onboardings" decision. Each opening = a new wave / table section.
3. **Pull replays.** `query-session-recordings-list` with `date_from` = day of last update (or cohort start), `order=start_time ASC`, high `limit`, property filter `{type:person, key:onboarding_variant, operator:exact, value:["agent"]}`. Authoritative session source.
4. **Map distinct_id → email.** The recordings list returns `email:null`. Run `execute-sql`:
   `SELECT distinct_id, any(person.properties.email) email, min(timestamp) first_seen, max(timestamp) last_seen FROM events WHERE person.properties.onboarding_variant='agent' AND timestamp > '<cohort_start>' GROUP BY distinct_id ORDER BY first_seen ASC`
   **Dedup by email** — users have a pre-login + post-login distinct_id pair. A `last_seen` of `07:00:01` with no replay = a daily background event, not real activity.
5. **Update the canvas** (write method above).

### Canvas format

- One table per **wave** (`## Vague N — …`); rows chronological by first session.
- Active minutes for new waves; flag inflated/idle rows with `†` and footnote it. Keep returning cohort-1 rows in whatever convention they already use.
- Frame an in-progress wave as "en cours" + timestamp it (more users may land same day).
- Keep users with events-but-no-replay as "aucun replay" (don't drop them — roster count must reconcile with the opening size, e.g. +20).
- Footer filter note must say: the property doesn't distinguish waves → **isolate by first-activity date** (e.g. Vague 1 = 15–17/06, Vague 2 = 25/06).
