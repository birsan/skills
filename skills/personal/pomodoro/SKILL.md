---
name: pomodoro
description: Run pomodoro work sessions (default 25 min) with a labelled JSONL log, then prompt for short/long break or a fresh session when the timer rings. Also summarizes sessions by label for today, yesterday, this week, or all-time. Use when the user says "start a pomodoro", "begin a pomodoro for X", "take a break", "next pomodoro", or asks for a pomodoro summary / what they worked on today.
---

# Pomodoro

Drives a Pomodoro Technique loop on Windows: 25-min work session → 5-min short break (or 15-min long break after every 4th work session) → repeat. Every completed session is appended to `Documents\pomodoro-log.jsonl` with its label so daily and weekly summaries are possible.

## Starting a session

1. **Get a label.** If the user did not give one ("start a pomodoro"), ask: *"What's the label for this session?"* The label is what shows up in summaries, so prefer concrete phrases like `"PR #4521 review"` over `"work"`.
2. **Run the timer in the background.** Use the `Bash` tool with `run_in_background: true`:

   ```bash
   powershell -NoProfile -File skills/personal/pomodoro/scripts/start-pomodoro.ps1 -Label "<label>" -Type work
   ```

   Add `-Minutes N` only if the user explicitly asked for a non-standard duration. The script sleeps, beeps four times, then appends the log entry. The harness will notify you when it exits — do **not** poll or sleep.
3. **Don't block.** While the timer runs, continue helping the user with whatever else they ask. The bell + harness notification is the only signal you need.

## When the bell rings (script exits)

Count how many **work** sessions have completed in the current conversation so far (this one included).

- If it's the 4th, 8th, 12th … session → suggest a **long break (15 min)**.
- Otherwise → suggest a **short break (5 min)**.

Ask the user one question with three obvious choices: take the suggested break, start a new work session (ask for the new label, or reuse the previous one if they say "same"), or stop. If they pick a break, launch it the same way with `-Type short-break` or `-Type long-break` and `-Minutes 5` or `-Minutes 15`. When the break script exits, prompt for the next work session.

## Summary

When the user asks "what did I work on today / yesterday / this week" or "pomodoro summary", run:

```bash
powershell -NoProfile -File skills/personal/pomodoro/scripts/pomodoro-summary.ps1 -Range today
```

Valid ranges: `today` (default), `yesterday`, `week` (Monday-anchored), `all`. The script prints session count and minutes grouped by label, sorted by time spent. Only `work` entries are counted; breaks are skipped.

## Customizing the bell

The bell defaults to `C:\Windows\Media\Alarm01.wav` played 3×. The user can change it two ways:

- **Per-session** (one-off): pass `-BellPath "C:\path\to\bell.wav"` to `start-pomodoro.ps1`.
- **Persistent** (every future session): write `Documents\pomodoro-config.json` with a `bellPath` key. The script reads this file automatically. `-BellPath` still wins if both are set.

When the user says *"change my pomodoro sound to X.wav"*, *"use Y for the bell"*, *"set the pomodoro bell to …"*, etc.:

1. **Verify the file exists** with `Test-Path` before writing the config — a broken path silently falls back to `SystemSounds.Asterisk`.
2. **Write `Documents\pomodoro-config.json`**:

   ```powershell
   $cfgPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'pomodoro-config.json'
   @{ bellPath = 'C:\full\path\to\bell.wav' } | ConvertTo-Json | Set-Content -Path $cfgPath -Encoding utf8
   ```
3. **Play it once** so the user can confirm it sounds right:

   ```powershell
   (New-Object System.Media.SoundPlayer 'C:\full\path\to\bell.wav').PlaySync()
   ```

If the user just wants a different Windows-bundled sound, the options live in `C:\Windows\Media\` (`Alarm01.wav` … `Alarm10.wav`, `Ring01.wav` … `Ring10.wav`, `chimes.wav`, `chord.wav`, `notify.wav`, etc.). Offer a quick list with `Get-ChildItem C:\Windows\Media\*.wav | Select-Object Name`.

## Notes

- **Only completed sessions are logged.** If the user aborts before the bell, nothing is written. That is intentional — the log should reflect real focused time.
- **Log location is fixed** at `Documents\pomodoro-log.jsonl` so it survives across projects and shells. Pass `-LogPath` only if the user explicitly asks to log somewhere else.
- **The bell** plays via `System.Media.SoundPlayer.PlaySync()` (the standard route through the normal audio device — `Console::Beep` is unreliable on modern Windows). If the user reports they didn't hear it, suggest checking the volume mixer for "Windows default" output — the script itself ran (you saw the exit notification).
