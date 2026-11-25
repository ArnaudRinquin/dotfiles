---
name: product-analytics
description: Product analytics end-to-end — decide what to measure (house dashboard template, adoption → funnel → quality → cost → value), instrument PostHog events + session recordings, build dashboards, refresh the Slack replay canvases (AI-import, onboarding-agent), and post numbers to Slack. Use when asked to "refresh the import/onboarding canvas", "update the replays", "check metrics", "how is <feature> doing", "add events/tracking", or "build a dashboard".
---

# Product analytics

## Environments

- PostHog `eu.posthog.com`: **prod = project 1617**, recette+local = 1593. Flags must exist in BOTH projects.
- Replay deep-link: `https://eu.posthog.com/replay/{id}`
- Slack analytics home: **#agent-teetsh** = `C0APLG0HB1T`

## Measuring a feature — the house template

A feature dashboard = one `## emoji` text-tile section per rung:

0. **Contexte** — cohort/assignment volumes over time. Keeps N visible so small cohorts read as *directional*, never causal.
1. **📊 Adoption & KPI** — the north-star share: % of the outcome unit produced via the feature (`source`/mode breakdown; pick the unit users value — % of *fiches*, not % of imports). Plus unique users, volume, requests by surface.
2. **🎯 Funnel** — `:opened → … → :created/applied` per kind; success/application rate as its own tile. Add a diagnostic sub-funnel where the drop concentrates (agent onboarding: panel → first action).
3. **⏱️ Vitesse / time-to-value** — p50/p90 from entry to outcome; bucket histograms for long tails; for variants: delay to first activation.
4. **🔍 Qualité du résultat** — is the output good? Kept-vs-discarded (conservation rate), mismatches, ambiguities/questions per run, items per outcome, response shapes.
5. **⚠️ Fiabilité & échecs** — failure rate, errors by reason. Agent features: `turn_outcome` distribution + per-tool health (`err_all` vs `infra`), actions-per-turn.
6. **⏱️ Performance** — operation durations p50/p90/p95, LLM latency by purpose.
7. **💸 Coût** — tokens/cost by purpose, then **normalized**: per outcome created, per active user, per assigned user, per paid conversion (LLM-CAC floor).
8. **🔁 Récurrence & valeur** — retention where the returning event is the *useful action*, NOT `$pageview` (known flaw to avoid); recurring users (2+); downstream value proxies: post-use consultation >1j, time to first PDF/export, feature-activation steps (`META:*:UserActivated`), paid conversion ≤30j vs control.

Not every feature needs every rung — but skipping one should be a decision, not an omission.

### Dashboard practices

- **Every tile gets a description**: its tier/section, definition, and caveats ("N petit → directionnel", known instrumentation gaps + their ticket). The dashboard description carries the cohort-spine + reading caveats.
- Variant comparisons: cut every tile by variant; state whether assignment was random (causal) or capped/first-N (directional).
- PostHog gotcha: funnels + event-property breakdown silently compute empty groups — use per-variant HogQL tables instead.

## Instrumenting

- Event naming: `Entity:action` — PascalCase entity, camelCase action: `EdtImport:documentSubmitted`, `Programmation:created`. Standard funnel steps: `:opened`, `:documentSubmitted`, `:analyzed`, `:questionsSubmitted`, `:created`.
- Frontend narrates the funnel; backend confirms the outcome with an authoritative event carrying props (e.g. `AiImport:created` with `kind`). Compute KPIs from backend events, engagement from frontend ones.
- Creation events carry `source` so "% via IA"-style splits stay possible later.
- Cohort spine: person property only if long-lived (`onboarding_variant`); otherwise **event-based** — feature flags get removed at GA, never build a cohort on one.
- Session recordings: `startSessionRecording(true)` on the surface's mount → every visit to that surface has a replay.

## Checking numbers

- SQL over `events` (`execute-sql` MCP) is authoritative; report unique users AND event counts.
- `active_seconds` is the duration truth — raw recording duration overstates 4–5× with idle tabs.
- Person props on events = value at ingest time, not the person's current value.
- The MCP recordings filter can't express "session contains event X" — roster session_ids via SQL first, then `query-session-recordings-list` with `session_ids`.

## Posting to Slack

Headline first (one strong line), then 3–5 compact bullets, dashboard + canvas links. Create with `slack_send_message_draft` — **never auto-send**. One attached draft max per channel; on `draft_already_exists`, report the text inline instead.

## Replay canvases

Two live canvases are maintained under this skill. Cohort spines, procedures, and the **CRITICAL Slack canvas API gotcha** are in [replay-canvases.md](replay-canvases.md) — read it before any canvas edit.
