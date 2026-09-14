# Capacity

Produce a **decision**, not a utilisation chart. "94% utilised" is unactionable; "15 Oct needs
two more engineer-weeks in checkout, and the only source is descoping the reporting work" is.

## The three questions

1. **Does the plan fit?** Per initiative: fits / does not / cannot tell, with the shortfall and
   which dates are unachievable.
2. **Can we take on X?** Never yes without naming what X displaces. A team with a plan has no
   spare capacity, only reprioritisation.
3. **Who is over-committed?** Per person, with what to take off them.

## Available engineer-weeks

Per person per week in the horizon, start at 1.0 and multiply. Every factor is the share of the
week that **remains available** — `0.5` loses half, `0` loses the week.

| Factor | Source | Default |
|---|---|---|
| `Alloc %` | `team.md` | as stated |
| Leave | `team.md` `Away`, pro-rata by working days | — |
| `On-call factor` | `team.md` `On-call`, that week only | 0.5 |
| `Ramp factor` | `team.md` `Ramp`, until the ramp month | 0.5 |
| `Notice factor` | `team.md` `Ramp: leaving <date>`; 0 after the date | 0.5 |

Values live in the `capacity` block of `state/stakeholders.md`. Sum per person, then per focus
area, then total.

`On-call factor: 0` where on-call consumes the whole week. Two consequences to state out loud:

- With factor 0 and an *n*-person rota the team permanently loses `1/n` of its capacity. That is
  a structural cost and belongs in the answer.
- **Do not discount it in `Alloc %` as well.** `Alloc %` covers commitments spread across every
  week (support rota, interviewing, a standing share on another team); the factors cover
  specific weeks. If a person has a reduced `Alloc %` mentioning on-call *and* on-call weeks
  listed, say so and ask which to keep.

**Never add a generic productivity factor.** These numbers are the user's; an invented
multiplier on top hides the assumption and makes the model unfalsifiable.

## Demand

`Remaining` in `initiatives.md` — rough engineer-weeks, the user's estimate.

No `Remaining`? Ask. Can't estimate? Mark it **unsized**, exclude it, and say the answer is
incomplete. Never infer size from the target date or how big the goal sounds: a guessed
denominator gives a confident wrong answer, which is worse than "cannot tell you yet".

An initiative's focus area is its owner's `Focus area`. One genuinely spanning two areas should
be two rows; if it isn't, say which area you assigned and that the split is a guess.

## Weeks are not fungible

A checkout specialist's week is not a data-pipeline specialist's week. Report availability **per
focus area** as well as total, and **never net a surplus in one area against a deficit in
another**. Totals comfortable but one area short → that goes in the headline. This is the most
common way a capacity model lies to its owner.

## Slack

Above the `No-slack threshold` (default 85%) the plan **does not fit**, whatever the arithmetic
says — interrupts, escalations and the unknown work of the next six weeks come from the same
pool. Report it as no-slack, not as fitting.

## Output

- **Headline** in one line: fits / does not fit / cannot tell.
- Shortfall per focus area, as a **range** — rough inputs make a decimal false precision.
- Which dates are unachievable, and roughly by how much.
- What would have to move, as concrete options with consequences.
- Per-person over-commitment.
- Assumptions used, including every default not overridden.

## Writing

Writes nothing by default: the model is a calculation, not a record.

The conclusion is worth keeping. Offer it to `state/risks.md` as a `decision` ("2026-09-04: v3
cannot land before December at current staffing") or an `ask` ("one engineer for six weeks, or
descope the migration tooling"). That is what stops the question being re-litigated next month.
