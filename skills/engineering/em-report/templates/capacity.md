A decision document. Lead with the answer, then the arithmetic that supports it, then what to
do about it. Drop sections with nothing in them — except `Assumptions`, which is never dropped.

Ranges, not point values. Per focus area, never a single netted total.

---

# Capacity — {{horizon}}

state at `{{commit}}`, captured {{last_capture}}

## Answer

**{{fits | does not fit | cannot tell}}** — {{one line: the shortfall and where it is}}

## Available

| Person | Focus area | Weeks available | Deductions applied |
|---|---|---|---|
| {{person}} | {{focus}} | {{weeks}} | {{deductions}} |

| Focus area | Available | Committed | Balance |
|---|---|---|---|
| {{focus}} | {{available}} | {{committed}} | {{balance}} |

## Demand

| ID | Initiative | Remaining | Focus area | Target | Achievable |
|---|---|---|---|---|---|
| {{id}} | {{initiative}} | {{remaining}}w | {{focus}} | {{target}} | {{yes/no, by how much}} |

Unsized, excluded from the arithmetic:

- {{id}} {{initiative}} — no estimate, so this answer is incomplete

## What would have to move

- {{option}} — {{consequence}}

## Over-committed

- {{person}} — {{detail}}, suggest taking {{what}} off them

## Assumptions

- An on-call week counts {{on_call_factor}} of a week; a ramping engineer counts {{ramp_factor}}
- No-slack threshold {{threshold}} — a plan above it is reported as not fitting
- `Remaining` estimates are the manager's own, treated as ±50%
- Weeks are not netted across focus areas
- {{any default not overridden, listed explicitly}}
