# People contract

`people/<key>.md`, keyed by `Key` in `state/team.md`. The key never changes. Files are never
deleted when someone leaves — the record outlives the reporting line.

Examples below are fictional.

## `people/<key>.md`

```markdown
# R. Alvarez
key: alvarez · joined: 2024-03-11 · cadence: weekly

## Context

Wants to move toward system design ownership; said 2026-06 they are not interested in
management. Prefers written feedback ahead of a conversation, not during it.

## Growth areas

- scope: agreed 2026-07-02 — lead a piece of work spanning more than one team
- communication: agreed 2026-07-02 — write the design doc before the implementation, not after

## 1:1 log

### 2026-08-21

- discussed: cutover sequencing, the on-call rota clash in September
- they raised: wants a decision on whether v1 support ends this year; frustrated by the
  Identity dependency
- I committed to: chase Identity for a date by 2026-08-28 [done 2026-08-27]; ask the PO about
  v1 end-of-life
- open: on-call swap for 14-18 Sep

## Evidence

| Date | Dimension | What happened | Source |
|---|---|---|---|
| 2026-08-28 | ownership | Took over the cutover plan when the owner went on leave, re-sequenced it, told the affected teams before they asked | my observation, INI-005 |
| 2026-08-12 | technical depth | Found the p99 regression was connection-pool exhaustion, not the query, after two others had looked | INI-004, review thread |

## Concerns

| Date raised | With them on | What | Status |
|---|---|---|---|
| 2026-07-30 | 2026-07-30 | Design docs arriving after implementation started, twice | improving, revisit 2026-09 |
```

- `cadence` on the header is what makes an overdue 1:1 detectable rather than merely forgotten.
- `Context` — slow-changing, always sourced to when they said it. A two-year-old aspiration
  quoted as current is worse than none.
- `Growth areas` — carry the date agreed. An area nobody agreed to is your opinion, not a growth
  area.
- `1:1 log` — four parts, and **`I committed to` is the one that matters**: it surfaces at the
  next prep, the only reliable defence against quietly dropping a promise. Commitments close in
  place — `[done 2026-08-27]` or `[dropped 2026-09-04: PO decided v1 stays]` — never deleted,
  never silently carried forward. Prep shows open ones with how many meetings they have survived.
- `Evidence` — dated, specific, sourced. See `dimensions.md`.
- `Concerns` — two dates, and **the raised-with-them date is mandatory**. No conversation yet
  means no row; say so instead.
- Never delete from any section. Supersede with a newer dated entry.

## `people/inbox.md`

Zero-friction in, drained later — but drained **per person** during that person's `log` run, not
in bulk.

```markdown
## Notes

- alvarez: handled the escalation from the payments team really well, unprompted
- nakamura asked about the senior criteria again - need a real answer
- 09-02 okafor mentioned being bored on the pipeline work

## Open questions

- Has the on-call swap for alvarez been agreed? (opened 2026-09-04)

## Processed

- 2026-08-28 "alvarez took over the cutover plan" -> alvarez.md evidence, ownership
```

- Prefix with a key where obvious; unprefixed notes are matched at drain time, and asked about
  when ambiguous.
- A note that reads as an evaluation ("nakamura is struggling") drains as a **prompt to observe**,
  never as evidence. It goes nowhere until there is an incident and a conversation.
- Unplaced notes stay in `Notes` and show at that person's next prep.
