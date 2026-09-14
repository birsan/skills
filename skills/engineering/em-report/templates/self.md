The manager's own working view, rendered first and alone unless outward audiences were named.
Exhaustive, ordered by action pressure, tables so it scans in one pass. No framing, no polish.

Sort `Needs me now` by date pressure within the `Attention horizon` from `stakeholders.md`. Drop
empty sections except `Needs me now` and `Inbox` — say those are empty, since an empty attention
list and a drained inbox are both worth knowing. The blockquote appears only when the state is
stale (interview skipped, or last capture older than a cycle).

---

# {{date}} — my view

> **State is {{capture_age}} old** — last capture {{last_capture}}. Dates below are only as
> good as that.

changes since `{{period_start}}` ({{period_days}} days) · state at `{{commit}}` · inbox {{unprocessed_count}} unprocessed, {{open_question_count}} open questions

## Needs me now

- [ ] {{what}} — {{why_now}} — by {{by_when}}

## Changed since {{period_start}}

| Change | Item | Was | Now | Why |
|---|---|---|---|---|
| slipped | {{initiative}} | {{old_target}} | {{new_target}} | {{reason}} |
| shipped | {{item}} | | | {{who}} |
| at risk | {{initiative}} | {{old_confidence}} | {{new_confidence}} | {{reason}} |
| resolved | {{risk_id}} | open | closed | {{resolution}} |

## Initiatives

| ID | Initiative | Status | Target | Conf | Owner | Last moved |
|---|---|---|---|---|---|---|
| {{id}} | {{initiative}} | {{status}} | {{target}} | {{confidence}} | {{owner}} | {{last_change_date}} |

## Dependencies in flight

Open rows only, both directions, soonest due first.

| ID | Dir | Counterparty | Item | Due | Status | Waiting on |
|---|---|---|---|---|---|---|
| {{id}} | {{direction}} | {{counterparty}} | {{item}} | {{due}} | {{status}} | {{owner}} |

In a read-only run, hang each pending note under the row it would change so nothing is hidden by
state not being written:

    ! pending note ({{note_date}}): "{{note_text}}" -> {{would_change}}

## Open risks and asks

`Age` is days since `Opened`. Past the `Ask age limit`, an ask is either not really needed or
not really asked — chase it or drop it.

| ID | Type | Age | Description | Owner | By when |
|---|---|---|---|---|---|
| {{id}} | {{type}} | {{age_days}}d | {{description}} | {{owner}} | {{by_when}} |

## Capacity flags

{{committed_pct}} of available weeks committed over the next {{horizon}} — {{slack_verdict}}

- {{person}} — {{flag}} ({{detail}})

Worth raising: allocation over 100%, away within two weeks, on-call this cycle or next, ramping,
notice period, sole owner of more than one at-risk initiative. The committed line is capacity
mode in one line, computed the same way (`references/capacity.md`) — omit it when initiatives are
unsized, and say why.

## Gone quiet

No update for two cycles: either done, or the next surprise.

- {{id}} {{item}} — stale since {{date}}

## Inbox

- unplaced: {{note}}
- unanswered: {{question}} (opened {{opened}})

## Needs confirmation

Each is also parked under `Open questions` so it outlives this report.

- {{unknown}}

## Sources consulted

- state at `{{commit}}`, captured {{last_capture}}
- {{source}}
