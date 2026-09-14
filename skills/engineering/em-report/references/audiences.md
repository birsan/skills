# Audience renderings

Same facts, five altitudes. One report lightly reskinned gives every audience a document
optimised for someone else. Read the matching block in `state/stakeholders.md` first — it
overrides these defaults.

## Me (the manager)

Rendered first, and it inverts the outward rules.

- **Exhaustive, not curated** — every open initiative, dependency, risk and ask.
- **Ordered by action pressure**, soonest first; not by importance or reporting structure.
- **No framing** — no mitigation-per-risk discipline, no single-ask rule. This is the only view
  where "I don't know why this slipped" is an acceptable cell value.
- **Ageing surfaced** — asks and risks carry age in days; rows untouched for two cycles are
  reported as gone quiet. Both are where the next surprise comes from.
- **Capacity flags** — allocation over 100%, imminent absence, on-call, ramping, anyone sole
  owner of more than one at-risk initiative.
- **Inbox state visible** — unplaced notes and unanswered questions, reported even when empty.
  A silently growing inbox is how the model rots.
- **State age and resolved period on the header**; stale state warns above the tables, not in a
  footnote.

Tables, so it scans in one pass. Empty attention list → say so; that is information.

**Omit:** nothing open.

## Manager / skip-level / exec

Deciding where to spend attention and money, in under a minute, on a phone.

- 5–8 lines. If it scrolls, it failed.
- Lead with committed-initiative status and date, not activity.
- Every risk carries a mitigation and an owner — without one it reads as a complaint.
- One explicit ask, or none. Three means nothing gets decided.
- No tooling names, implementation nouns, per-person detail or sprint mechanics.
- Don't editorialise on other teams; state the dependency and its date.

**Omit:** velocity, ticket counts, names except as initiative owners.

## Product / PO

Deciding scope and sequencing, and making external commitments.

- Scope × date × confidence per initiative, confidence in words with the reason.
- What slipped and *why* — mechanism, not apology.
- The trade-offs actually available: "hold 15 Oct without the migration tooling, or 29 Oct with
  it".
- What you need from them to hold the date, with a by-when.
- Ticket detail only where it changes a scope decision.

**Omit:** engineering rationale that moves no decision; capacity mechanics — give the
conclusion, not the model.

## Peer teams / dependency owners

**One report per counterparty**, filtered from `dependencies.md` on `Counterparty`. Nobody reads
other teams' rows.

- Two lists: what we owe you, what you owe us — each with owner and date.
- Blockers factually, no blame, with the date consequence: "blocked on the token endpoint, needed
  by 12 Sep to hold our 15 Oct date". The consequence is what creates movement.
- Short and paste-ready.
- One concrete next step, with an owner.

**Omit:** your initiative status, your risks, your capacity.

## My own team

They need context for prioritisation, and to know their work was seen.

- What changed and why, especially reprioritisation. An unexplained priority change costs a
  senior engineer's trust fastest.
- Decisions and their reasoning, including ones that went against team preference. Say who
  decided.
- Specific credit, by name. Generic praise reads as filler.
- What you need from them, concretely.
- What you are carrying for them — escalations in flight are invisible work.

**Omit:** exec framing of their own work; anything about an individual they haven't heard from
you directly.

## Cross-cutting

- Dates as `YYYY-MM-DD` or an explicit week. Never "soon" — the report outlives the week.
- **State the period in the header.** Each audience has its own window, so "what changed" means
  something different in each report.
- No status colours without definitions. If RAG is mandated, define thresholds in
  `stakeholders.md` and apply them mechanically.
- `Needs confirmation` whenever anything is unconfirmed. Never dropped for tidiness.
- Write in the user's voice — they send it under their own name.
