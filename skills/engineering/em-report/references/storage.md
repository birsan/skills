# Storage

A **private GitHub repo of markdown**, cloned on every machine. The remote is the source of
truth, the working copy a cache: pull at the start, push at the end, and context never lives on
one machine only.

Git rather than a notes app because the version history is load-bearing — it *is* the baseline
every report diffs against — and because plain files keep connector auth out of the hot path.

Nothing is ever published out of these repos. Reports are saved and shown; the user sends them
by hand or not at all.

## Repo layout

```
state/
  inbox.md team.md initiatives.md dependencies.md risks.md stakeholders.md
reports/
  <YYYY-MM-DD>/{self,exec,product,peer-<team>,team}.md
people/            (only if em-people shares this repo)
  README.md inbox.md <key>.md
```

**If `people/` is present, this repo can never be shared.** Access is per repository, not per
directory, so a collaborator added for the delivery tables also gets 1:1 notes and performance
observations — retroactively and permanently, since the history keeps them. To share delivery
state, extract `state/` into its own repo; or set `people.sameRepo: false` and give people its
own remote.

`state/inbox.md` is the file meant to be edited by hand between sessions, including from a phone
via the GitHub web editor. The tables can be too, but the inbox is where information is
*supposed* to arrive unstructured.

No snapshot directory: every capture is a commit, so any report diffs against any past date.
Report sets are named by date, and the newest per audience sets the next report's default period.

## `~/.claude/em/config.json`

Per machine, pointers only — never content, never secrets. May differ between machines.

```json
{
  "identity": { "name": "", "team": "" },
  "delivery": {
    "remote": "https://github.com/<owner>/<repo>.git",
    "path": "C:/Users/<user>/.claude/em/state",
    "branch": "main"
  },
  "people": {
    "enabled": false,
    "sameRepo": true,
    "dir": "people",
    "remote": "",
    "path": "",
    "branch": "main"
  },
  "sources": { "repos": [] }
}
```

- `delivery.path` — the clone; `state/` and `reports/` sit inside it.
- `people` — with `sameRepo: true`, the `dir` directory inside the delivery clone and
  `remote`/`path` are ignored. With `false`, its own repo, which is the only configuration that
  leaves delivery state shareable.
- `sources.repos` — local repo paths to read `git log` from during capture.

## Sync

`scripts/em_sync.ps1`, and `em_init.ps1` for setup:

- `em_init.ps1 -Remote <url> [-Path <clone>]` — clone, or scaffold and push into an empty repo.
  Also scaffolds an already-cloned-but-empty repo. `-People -SameRepo` adds `people/`.
- `-Action pull` — fast-forward only. A non-fast-forward or dirty tree **stops the workflow** and
  is shown to the user. Never merge, rebase or discard the other machine's commits: a lost
  capture removes a period from every future report's history.
- `-Action status` — porcelain status, last capture and last report dates.
- `-Action push -Message <msg>` — stage, commit, push, announce the commit.
- `-People` on any action targets the people tier.

The working copy is disposable. If it reaches a state you cannot resolve cleanly, re-clone rather
than force-pushing over the remote.
