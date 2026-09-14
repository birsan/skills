---
name: em-report
description: Engineering-manager reporting, capacity modelling and delivery-state tracking from a private git repo of markdown. Modes - note (jot a raw line into an inbox), report (capture what changed, then render the manager's own working view plus any outward view asked for: exec/skip-level, product/PO, one per peer team or dependency owner, the team itself), capacity (does the plan fit, what would taking on X displace, who is over-committed). Use for "my view", "what needs my attention", "weekly report", "what would the exec see", "log:", "X slipped", "Y is unblocked", "does this fit", "can we take on X", initiative or dependency status, "what changed this week".
---

# EM reporting

Reports render `state/`; they are never written from scratch. "What changed" is a git diff of
`state/` over a chosen period — there is no stored baseline and nothing to snapshot.

## Rules

1. **Never send.** No posting, messaging, emailing or publishing. Show and save; the user sends
   by hand. Do not offer to send.
2. **Every figure traces** to a `state/` file or a command run this session. Never estimate,
   smooth or carry forward silently.
3. **Unknowns are stated, not filled** — in the report's `Needs confirmation`, *and* parked
   under `Open questions` in `state/inbox.md` so they outlive the report.
4. **Capture before render.** Steps 1 and 2 are mandatory.
5. **Never mix altitudes** (`references/audiences.md`). `self` is the exception: exhaustive and
   blunt, never curated, and its bluntness never leaks into an outward view.
6. **People data never enters `state/`.** Performance, personal circumstances, promo evidence
   and 1:1 content belong to `em-people`. Offer to route it there; never write it here.

## Modes

| Mode | Triggered by | Writes |
|---|---|---|
| `note` | "log:", "note:", "for the record" | `inbox.md` `Notes` only |
| `report` | "my view", "what needs my attention", "weekly report", "what would the exec see" | state, inbox, `reports/` |
| `capacity` | "does this fit", "can we take on X", "who is over-committed" | state, inbox — never the model |

- **`note`** — append the user's words to `Notes`, date-prefixed, otherwise verbatim. No
  interpretation, no follow-up question, do not read the rest of state. Push, confirm in one
  line, stop. Being expensive here is a bug: this is what keeps the model fed.
- **`report`** — Steps 0 to 5. Always captures first, so it is never built on knowingly stale
  state. Running it twice in a day is harmless.
- **`capacity`** — Steps 0 and 1, then compute per `references/capacity.md` (read it first) and
  `templates/capacity.md`. The model is never saved; offer its conclusion to `risks.md` as a
  `decision` or an `ask`.

No state yet — no config, or empty tables? Render from the fictional examples in
`references/state-contract.md`, labelled a sample of the format rather than a report.

## Step 0 — Config and sync

Read `~/.claude/em/config.json`. Missing → ask for the private repo URL, then
`scripts/em_init.ps1 -Remote <url>` (see `references/storage.md`). Present →
`scripts/em_sync.ps1 -Action pull`; on divergence or a dirty tree **stop and show the user**,
never resolve state conflicts silently.

Say which repo and commit you are on. Last capture is
`git -C <delivery.path> log -1 --format=%cs -- state/`; if it is older than `Cycle` (the `self`
block of `stakeholders.md`, default weekly), say so and interview longer.

## Step 1 — Capture

Read `initiatives.md`, `dependencies.md`, `risks.md`, `team.md`. Scale the work to what is
pending — a morning glance and a Friday report should not cost the same:

| Situation | Action |
|---|---|
| Inbox empty, captured today | skip the interview, go to Step 3 |
| Inbox has entries | drain, then ask only what stayed ambiguous |
| Last capture over a day old | drain, then the interview below |
| "just render", "don't ask" | apply what maps unambiguously, leave the rest in `Notes` and list them in the report's `Inbox` section, stamp the state's age on the header |
| "just show me", "quick look" | read-only: compute the drain, show what each pending note *would* change inline against its row, write no state, no report file, no commit |

The drain is never *skipped* — at most computed and shown instead of written. A report rendered
while an undrained note contradicts a row is the one confidently wrong document this skill can
produce.

**Drain.** `Notes` is freeform text dumped between sessions. Interpret each entry and show the
mapping before writing:

```
"identity says october for the endpoint" -> DEP-012 due 2026-09-12 -> 2026-10-?? (vague, will ask)
```

Ambiguous entries become questions, not guesses; unplaceable ones stay in `Notes` and are
reported. Then fold in any `Open questions` the user answered inline.

**Cheap pull.** `git log --since=<last capture> --oneline` in each `sources.repos` path.

**Interview.** One message, grouped, answerable in a couple of minutes, covering only rows that
could have moved and the inbox did not settle: initiative status, target and confidence, with
the reason; dependencies newly owed, blocked or unblocked; new or closed risks, decisions worth
logging; roster changes (delivery-relevant only); anything needed from a stakeholder. If they
paste raw meeting notes, parse to schema and show what you extracted first. An interview that
regularly takes ten minutes is too broad.

## Step 2 — Update state

Read-only run: skip. Otherwise apply per `references/state-contract.md`:

- Status, date and confidence changes need a **dated reason** in `Notes`.
- Date it by **when it happened**, not when you drained it.
- Confidence downgrades are healthy; a date that never moves is fiction.
- New risks and asks get an ID and open date; closing one records the resolution.
- Never drop rows you learned nothing about; mark `stale since <date>` after two cycles.
- Finish the drain: move acted-on entries to `Processed` annotated with the row IDs they became.
  Never delete a note.

## Step 3 — Period and diff

`git rev-list -1 --before=<date> HEAD`, then `git diff <commit> HEAD -- state/`.

**Ask which period**, offering the default:

> Since 2026-08-28 — the last exec report, 7 days? Or a different period?

Resolve in order: a period the user named; the newest `reports/<date>/<audience>.md` (per
audience windows drift apart, which is correct); otherwise 7 days. Skip the question if they
named a period, said "usual", or asked for a quick look.

**Always print the window in the header** — a changed-list cannot be judged without it. Over
three weeks, say so before rendering; it stops being a narrative.

Classify each change: shipped, slipped, newly at risk, resolved, scope changed, capacity
changed. `git log --since=<period start> -- state/` gives the intermediate moves rather than
only the net one, and churn is worth reporting. Nothing material changed? Say so plainly.

## Step 4 — Render

`templates/self.md` first, and alone unless outward audiences were named. Its header carries the
period and the state's age; where the interview was skipped, warn above the tables that the
state is N days old and its dates are suspect.

Outward views: `stakeholders.md` for profiles, `templates/<audience>.md` for shape,
`references/audiences.md` for content, omissions, length and tone — follow it over your own
sense of what is interesting. Peer reports are **one per counterparty**. Asked only for "the
weekly report"? Show `self`, then ask which outward views they want.

## Step 5 — Hand off

`note` pushes its line and stops. A read-only run stops here: show the reports, write nothing,
and say what is still pending.

- Show each report in chat, in full.
- Save to `reports/<YYYY-MM-DD>/<audience>.md` — the record of what each audience was told, and
  what the next period is measured from.
- Provenance footer (`Sources consulted`, resolved period, `Needs confirmation`) on the **saved**
  copy of an outward report only, so the chat version stays clean to paste. `self` shows it in
  both.
- `scripts/em_sync.ps1 -Action push -Message "report: <date> <audiences>"`, then report the
  commit.
- Stop. Sending is the user's move.

## References

- `state-contract.md` — `state/` schemas. Read before writing state.
- `audiences.md` — per-audience content, omissions, length, tone.
- `capacity.md` — how available weeks are computed and how the answer must be framed.
- `storage.md` — config, repo layout, sync and conflict semantics.

## Related

`em-people` — 1:1 prep, growth evidence, review drafting. A separate skill for its own data
model and note stream; it shares this contract and the sync script and reads `state/` read-only.
Its `people/` directory may sit in this same repo, which makes the repo unshareable — see
`storage.md`.

Anything else that reads these tables belongs here as a mode rather than a new skill, or it
reimplements Steps 0 to 2. Drafting off-cycle messages — slip notices, escalations, scope
pushback — is the obvious next one.
