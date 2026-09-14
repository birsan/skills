---
name: em-people
description: One-to-one prep, growth evidence and review drafting for an engineering manager's direct reports, kept as dated markdown and joined read-only to em-report's delivery state. Modes - note (jot a raw observation), prep (read-only 1:1 prep), log (record a 1:1 afterwards), evidence (file an observation, read coverage, draft a review). Use for "prep my 1:1 with R", "what should I cover with R", "log my 1:1 with R", "note about R:", "what evidence do I have for R", "draft R's review", "where is R thin". Never writes to delivery state and never surfaces an individual in a team-facing report.
---

# EM people record

The specific thing someone did in October is gone by March, so reviews get written from
recency. This skill makes the small dated observation cheap to record and easy to retrieve.

Everything is **dated**, **specific** and **sourced**.

## Rules

1. **Never write to `state/`.** It is read-only from here, and nothing in a people file is
   quoted, summarised or hinted at in an `em-report` output.
2. **Delivery data is about work, not people.** An initiative slipping is a fact about the
   initiative. Never infer an evaluation, sentiment or trait from delivery state — use the join
   for *what happened* and let the manager supply the judgement.
3. **Nothing negative that has not been said to them.** A concern is filed only after it has
   been raised with the person, and records the date it was raised. Not had that conversation?
   Say so and offer to help prepare it.
4. **Evidence needs an incident, not an adjective.** "Strong ownership" is not evidence; "took
   over the cutover plan on 2026-08-28 when the owner went on leave" is. Ask for the incident.
5. **Never rate, rank or compare.** No scores, no "stronger than". Assemble evidence; the
   manager judges.
6. **Thin evidence is reported, not padded.** Say a dimension is unevidenced rather than writing
   around the gap.

## Storage

`people/` sits inside the delivery repo (`people.sameRepo` in `~/.claude/em/config.json`), one
file per person keyed by `Key` in `state/team.md`.

**That makes the delivery repo unshareable.** Access is granted per repository, not per
directory, so any collaborator added for the delivery tables gets 1:1 notes too, retroactively
and permanently. To share delivery state, extract `state/` into its own repo instead.

First run: `scripts/em_sync.ps1 -Action status -People`. Not enabled → run `em-report`'s
`scripts/em_init.ps1 -People -SameRepo`.

**Adding a person** — nothing works for them until the key exists, and a missing key fails
silently:

1. Set their `Key` in `state/team.md` (short lowercase slug), and `Git` if you want shipped-work
   attribution. This is the only write into `state/` this skill may ask for — confirm it with
   the user and keep to `em-report`'s contract.
2. Create `people/<key>.md` from `references/people-contract.md`.
3. Ask two things only: 1:1 cadence, and any already-agreed growth areas.

**Everyone on the roster gets a file, created when they join it.** Empty sections are correct for
someone who joined yesterday; a missing file is indistinguishable from neglect. Don't wait to be
asked.

Every mode reconciles roster against files: report anyone with no `Key`, any key with no file,
and any file whose key has left the roster (usually a leaver, whose file is kept deliberately).

## The delivery join

Read-only, facts only.

| Source | Gives |
|---|---|
| `state/team.md` | level, focus area, allocation, leave, on-call, ramp |
| `state/initiatives.md` | what they own, its status, target, confidence |
| `state/dependencies.md` | what they owe and are owed |
| `state/risks.md` | risks and asks they own |
| `git log --since=<last 1:1> -- state/` | what moved under their name since you last spoke |
| `git log --author=<Git> --since=<last 1:1>` in `sources.repos` | what they shipped |

People files never duplicate any of it — level and focus area are looked up, so they cannot
drift.

## Modes

| Mode | Triggered by | Writes |
|---|---|---|
| `note` | "note about R:", "for R's file" | `people/inbox.md` only |
| `prep` | "prep my 1:1 with R", "what should I cover with R" | nothing |
| `log` | "log my 1:1 with R", "here is what we discussed" | their `1:1 log`, evidence, inbox drain |
| `evidence` | "what evidence do I have for R", "draft R's review", "where is R thin" | evidence rows, or nothing for a read |

- **`note`** — append verbatim to `people/inbox.md`, date-prefixed, with the key if obvious. No
  interpretation, no follow-up. Push and stop; this path must stay free.
- **`prep`** — render `templates/prep.md`. Writes nothing and drains nothing: it runs minutes
  before a meeting. Pending notes about that person appear inline, marked not yet filed.
- **`log`** — append a dated `1:1 log` entry per `references/people-contract.md`, drain their
  pending notes, and propose any evidence rows for confirmation before writing. An evidence row
  is a claim about a person.
- **`evidence`** — read: what exists by dimension, and what is unevidenced. Write: file an
  observation, or draft a review via `templates/review.md`.

## References

- `references/people-contract.md` — per-person file and inbox schema. Read before writing.
- `references/dimensions.md` — the dimensions, and what counts as evidence.

`em-report` owns `state/` schemas. This skill keeps its own copy of `em_sync.ps1` because skills
install independently and cannot rely on a sibling's path.
