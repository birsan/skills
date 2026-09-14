# Personal and Engineering Skills

A collection of [Claude Code](https://claude.com/claude-code) skills for personal and engineering use.

## Installation

Install the [`skills`](https://www.npmjs.com/package/skills) CLI and add this repository globally:

```bash
npm install -g skills
skills init --global
skills add birsan/skills --global
```

## Skills

### Engineering

- **[`windows-driver-cleanup`](skills/engineering/windows-driver-cleanup/SKILL.md)** — Find and remove old, duplicate third-party drivers on Windows by keeping only the newest version of each OEM driver package. Defaults to a safe deletion (skips drivers in use); `-Force` is opt-in. Includes a PowerShell script with `-WhatIf` dry-run support and `ConfirmImpact='High'` per-item prompts. Use when cleaning up the Windows DriverStore or reclaiming disk space from stale driver versions.
- **[`pr-review-loop`](skills/engineering/pr-review-loop/SKILL.md)** — Iterate through unresolved review comments on a GitHub PR: fix or won't-fix each, reply, resolve, refresh the PR description, hand off the re-request to the user, then poll for the next round. Reviewer-agnostic — works for any bot or human reviewer. Use when addressing PR review comments or handling PR feedback round-trips.
- **[`em-report`](skills/engineering/em-report/SKILL.md)** — Engineering-manager reporting, capacity modelling and delivery-state tracking, rendered from a private git repo of markdown. Three modes: **note** (append a raw thought to a freeform inbox, seconds, no interpretation), **report** (drain the inbox into structured state, ask what period to cover, then render the manager's own working view — everything open, ordered by what needs action, with ageing asks, rows gone quiet and capacity clashes surfaced — plus any outward view asked for: exec/skip-level, product/PO, one per peer team, the team itself), and **capacity** (available engineer-weeks after leave, on-call and ramp against the plan, answering only whether it fits, what taking on more would displace, and who is over-committed). There is no stored baseline — git history is the baseline, so any report diffs against any date, and each audience's default window is "since you last reported to them". Never sends anything; reports are shown and saved, and delivered by hand.

- **[`webreq`](skills/engineering/webreq/SKILL.md)** — Run, store and organize HTTP requests as templated collections with per-environment contexts (base URL, bearer, account/tenant ids), kept in a user-chosen repo folder so they can be versioned. A dependency-free Node runner keeps output terse: one status line plus a truncated body, with `--pick`, `--dry` and `--out`. The agent maps free-text asks ("call the resource catalog in alpha for entity type X") onto stored requests, asks for missing variables or a fresh bearer on 401 instead of guessing, and stores secrets in gitignored `.local.json` overlays. Use when calling or testing an API endpoint, saving a request for reuse, or creating a request collection or context.

- **[`em-people`](skills/engineering/em-people/SKILL.md)** — One-to-one prep, growth evidence and review drafting for direct reports, kept as dated markdown and joined read-only to `em-report`'s delivery state. Four modes: **note** (a raw observation, seconds), **prep** (read-only — what you committed to last time, what they raised that is unresolved, what actually moved in their work since, notes not yet filed), **log** (record the meeting, drain notes, propose evidence rows), **evidence** (file an observation, read coverage by dimension, or draft a review strictly from filed evidence). Every entry is dated, specific and sourced: adjectives are refused in favour of incidents, delivery outcomes never become judgements about people, nothing negative is filed before it has been said to the person, and unevidenced dimensions are reported rather than padded. No ratings, no ranking, no comparisons.

### Personal

- **[`pomodoro`](skills/personal/pomodoro/SKILL.md)** — Run labelled 25-min pomodoro work sessions with a JSONL log in `Documents\pomodoro-log.jsonl`, ring a bell at the end, then prompt for a 5-min short break (or 15-min long break after every 4th session) or a fresh session. Includes a summary script that groups completed sessions by label for today, yesterday, this week, or all-time. Use when starting a pomodoro, taking a break, or asking what you worked on.

## Other useful skill packs

```bash
skills add mattpocock/skills --global
```
