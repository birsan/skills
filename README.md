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

## Other useful skill packs

```bash
skills add mattpocock/skills --global
```
