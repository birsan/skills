# State contract

Markdown tables under `state/`, one row per entity, stable IDs that are never reused. Editable
by hand in a browser or editor. Edit rows in place — never reformat a table wholesale, or the
`git diff` stops being readable.

Examples below are fictional.

## `state/team.md`

Delivery facts only. No performance, compensation, health or personal circumstance — those are
`em-people`'s.

```markdown
| Person | Key | Git | Level | Focus area | Alloc % | Ramp | Away | On-call | Notes |
|---|---|---|---|---|---|---|---|---|---|
| R. Alvarez | alvarez | ralvarez | Senior | Checkout service | 100 | full | 2026-09-14..18 | wk 38 | |
| T. Nakamura | nakamura | tnakamura | Mid | Reporting API | 60 | ramping to 2026-10 | | | 40% on support rota |
| S. Okafor | okafor | | Senior | Data pipeline | 80 | full | | wk 40 | 20% interviewing |
```

- `Key` — stable join key for `people/<key>.md`. Set once, never changed, not even when a name
  changes. Matching on display name breaks silently.
- `Git` — commit identity for attributing shipped work in `sources.repos`. Optional; blank skips
  attribution. Several identities (a handle and a corporate email) are **comma-separated**, and
  the skill joins them into one `--author` pattern. Never put a `|` in a cell, escaped or not —
  it renders fine but adds a column to every parser that splits on it.
- `Alloc %` — share of time available to planned initiative work after standing commitments.
- `Ramp` — `full`, `ramping to <YYYY-MM>`, or `leaving <YYYY-MM-DD>`.
- `Away` — date ranges, never reasons.

## `state/initiatives.md`

```markdown
| ID | Initiative | Goal | Owner | Status | Target | Deadline | Remaining | Confidence | Stakeholder | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| INI-004 | Checkout latency | p95 under 400ms | R. Alvarez | on-track | 2026-10-15 | | 6w | Medium | Web Platform PO | Confidence Medium since 2026-09-01: two consumer teams unscheduled |
| INI-005 | Reporting API v3 | Retire v1 endpoints | T. Nakamura | at-risk | 2026-11-02 | 2026-11-15 external | 9w | Low | Data PO | 2026-09-03 slipped from 10-19: blocked on DEP-012 |
```

- `Status` — `not-started`, `on-track`, `at-risk`, `blocked`, `shipped`, `dropped`.
- `Confidence` — **High**: would bet the date, work understood and staffed. **Medium**:
  plausible, one or two unknowns could move it. **Low**: don't plan downstream on it.
- `Target` — a date or `TBD`, and it is *your plan*. `TBD` is honest; an invented date is not.
- `Deadline` — a fixed date that is **not yours to move**, plus who owns it (`external`,
  `release train`, `contractual`, `compliance`). Blank for most rows, and blank means there is
  no wall, not that the target is soft.
  - `Target` must be on or before `Deadline`. A row where it isn't is already broken — say so
    rather than reporting it as on-track.
  - Every `Deadline` needs a **decide-by** `ask` in `risks.md`: the last date you can still act
    by cutting scope, adding people or negotiating, with the consequence of missing it. A
    deadline discovered on the day is unmanageable.
  - At-risk against a `Deadline` escalates **immediately** — it goes in `Needs me now` whatever
    the attention horizon says, not into the weekly changed-list.
- `Remaining` — rough engineer-weeks of effort left (not calendar duration), read only by
  capacity mode. Blank means **unsized**: excluded from the arithmetic, never guessed from the
  target date. It decays as work happens, so re-estimate it at capture when it moved materially
  and date the change in `Notes` — capacity mode reports an estimate older than a cycle as
  suspect.
- Focus area comes from the owner's `Focus area`. An initiative spanning two areas should be two
  rows — per-area arithmetic cannot represent a straddling row honestly.
- Any change to `Status`, `Target` or `Confidence` appends a **dated reason** to `Notes`. Highest
  value field in the model: every stakeholder question is "why?".

## `state/dependencies.md`

```markdown
| ID | Direction | Counterparty | Item | Our owner | Their owner | Due | Status | Blocker |
|---|---|---|---|---|---|---|---|---|
| DEP-011 | we-owe | Payments team | Event schema for refunds | T. Nakamura | L. Berg | 2026-09-19 | on-track | |
| DEP-012 | they-owe | Identity team | Token introspection endpoint | R. Alvarez | D. Moreau | 2026-09-12 | blocked | awaiting their sprint planning |
```

`Direction`: `we-owe` or `they-owe` — peer reports filter this table on `Counterparty`.
`Status`: `on-track`, `at-risk`, `blocked`, `done`.

## `state/risks.md`

One table, three types — they share a lifecycle and stakeholders read them together.

```markdown
| ID | Type | Opened | Description | Impact | Owner | Mitigation / Ask | Status | Closed |
|---|---|---|---|---|---|---|---|---|
| RSK-007 | risk | 2026-08-28 | Consumer teams not scheduled for v3 cutover | INI-005 slips to Dec | me | Escalating to Data PO wk 37 | open | |
| ASK-003 | ask | 2026-09-02 | Decision on deprecating v1 endpoints | Blocks cutover comms | Data PO | Need decision by 2026-09-12 | open | |
| DEC-002 | decision | 2026-08-20 | v1 endpoints supported until 2027-01 | Sets cutover deadline | me | | closed | 2026-08-20 |
```

`risk` may happen; `ask` needs something from someone; `decision` is settled, kept because
people re-litigate. **An ask without a named owner and a by-when is a wish** — fill both.

## `state/stakeholders.md`

Free-form blocks, one per audience; they drive rendering. `Delivery` records how the *user* sends
it by hand.

```markdown
## exec
- Who: A. Byrne (manager), P. Sandoval (skip-level)
- Cadence: weekly, Friday
- Delivery: user pastes into email
- Cares about: dates on committed initiatives, risks with a mitigation, headcount, cross-org blockers
- Omit: implementation detail, per-person detail, tool names
- Tone: 5-8 lines, outcome-first, one explicit ask
- Never include: anything about individual performance

## self
- Surface first: dependencies I am blocking, asks past their by-when
- Attention horizon: 2 weeks
- Ask age limit: 14
- Stale after: 2 cycles
- Cycle: weekly

## capacity
- Horizon: 8 weeks
- On-call factor: 0.5
- Ramp factor: 0.5
- Notice factor: 0.5
- No-slack threshold: 0.85
```

`self` and `capacity` hold thresholds rather than profiles, since the audience is the user:

- `Attention horizon` bounds `Needs me now`; `Ask age limit` is when an open ask is flagged as
  ageing; `Stale after` is cycles without an update before a row is reported gone quiet; `Cycle`
  is the rhythm used to judge whether the state itself is stale.
- `capacity` factors are the share of a week that **remains available** — see
  `references/capacity.md`. Omitted values fall back to the defaults there, and capacity mode
  lists which ones it fell back on.

## `state/inbox.md`

The one file with no schema. Accepts information at zero friction from anywhere, including a
phone via the GitHub web editor. Reports never read it directly — capture **drains** it into the
tables above.

```markdown
## Notes

- identity says october for the endpoint, no date
- retro: nobody owns the runbook. worth an initiative?
- 09-02 call with data PO - they want v1 gone before EOY, pushed back

## Open questions

- Has wk 38 on-call been reassigned? (opened 2026-09-04)
- Did Payments accept 2026-09-19 for DEP-011? -> yes, confirmed by L. Berg on 09-03

## Processed

- 2026-09-03 "reporting api slipping, identity hasn't scheduled" -> INI-005 target, DEP-012 status
```

- `Notes` — the user's, freeform, any format, no dates required. Never rewritten by the skill,
  only moved.
- `Open questions` — written by the skill when something couldn't be confirmed; the user answers
  inline whenever. Folded in at the next capture. This is what stops an unconfirmed date
  evaporating into a report footer.
- `Processed` — drained entries annotated with the row IDs they became, so a figure traces back
  to its note. Trim when long; durable provenance lives in each row's `Notes`.
- Unplaceable entries stay in `Notes` and are reported. **Never delete a note.**

## History instead of snapshots

No snapshot file, no `state/log/`. Every capture is a commit:

```
git rev-list -1 --before=2026-08-28 HEAD          # the commit
git show <commit>:state/initiatives.md            # the tables as they were
git diff <commit> HEAD -- state/                  # the change set
```

Which is why capture commits every time, even for one line: **the commit is the record.** An
uncommitted capture is a snapshot that never happened, and its period is invisible to every
future report.

## `reports/<YYYY-MM-DD>/<audience>.md`

The record of what each audience was told and when — and the newest file per audience is the
default period for that audience's next report.

The **saved copy** ends with a provenance footer; the chat version of an outward report does
not, so it stays clean to paste. `self` carries it in both.

```markdown
## Sources consulted
- state at commit <sha>, captured 2026-09-04
- period: since 2026-08-28 (last exec report)
- git log <repo path> since 2026-08-28
- manager interview 2026-09-04

## Needs confirmation
- Whether wk 38 on-call has been reassigned
```

Without it nobody can reconstruct how a date was set, including whoever set it.
