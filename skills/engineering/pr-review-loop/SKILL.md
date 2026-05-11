---
name: pr-review-loop
description: Iterate through unresolved review comments on a GitHub PR — fixing or won't-fixing each, replying, resolving, refreshing the PR description, then handing off to the user to re-request review and polling for the next round. Reviewer-agnostic — works for any bot or human reviewer; asks the user upfront whether to handle threads from all reviewers or just one. Use when the user asks to "address PR review comments", "go through the review", "handle PR feedback", or similar. Works in any repository.
---

# PR review loop

A repeatable cycle for getting a PR through review:

1. Pick scope: all reviewers or one specific reviewer login.
2. List the matching unresolved review threads.
3. For each thread, decide **fix** or **won't-fix**, apply the code change (if any), self-review the diff, commit, push.
4. Refresh the PR description to reflect the new state.
5. Reply on each thread (referencing the fix commit, or the won't-fix rationale) and resolve it.
6. **Ask the user to re-request review** in the GitHub UI.
7. Poll for the next review pass; when it arrives, repeat.

The skill uses `gh` (GitHub CLI) — no extra tooling. It is reviewer-agnostic; the same flow works for any GitHub user, App, or bot reviewer.

## When to use this skill

- The user says "address the review comments", "fix PR feedback", "iterate on the review", "handle review threads", or invokes a similar review-handling command.
- A PR has unresolved review threads and the user wants Claude to drive the round-trip end-to-end (read code, decide, fix, reply, resolve, then hand off the re-request to the user, then poll).

Do **not** invoke when:

- The user has not authorized pushing to the branch (this skill pushes commits).
- The PR is on a third-party fork without write access to the head ref.

## Step 0 — Load repo conventions before touching any code

Before reading any review thread, build a conventions snapshot. This reduces the review
surface by making the initial code conform to what reviewers will check.

```bash
# Check for convention files in priority order
for f in CLAUDE.md .github/copilot-instructions.md .editorconfig \
          .eslintrc* .prettierrc* pyproject.toml ruff.toml; do
  [ -f "$f" ] && echo "=== $f ===" && cat "$f"
done
```

From this snapshot, extract:
- **Naming rules** (camelCase, snake_case, file naming patterns)
- **Import ordering** (stdlib → third-party → local, or configured otherwise)
- **Error handling patterns** (exceptions vs. Result types, logging conventions)
- **Test expectations** (co-located vs. separate, naming pattern, required for PRs?)
- **Banned patterns** (any `// eslint-disable` comments or `# noqa` in existing code
  indicate known problem areas — don't introduce similar patterns)

Store this as your working `CONVENTIONS` reference. In Step 4 (fix/won't-fix), when a
CONVENTION-class comment conflicts with this snapshot, the snapshot wins and the comment
is won't-fix. When a BUG-class comment reveals a missing convention (e.g. "you should
always null-check here"), add a mental note to apply that pattern proactively on other
similar lines in the same PR — surface those as a batch fix rather than waiting for
Copilot to flag each one individually.

## Step 1 — Identify the PR

If the user named the PR (`#123`, a URL, or "this PR"), use that. Otherwise infer:

- If the working directory ends with a number that matches a PR number convention used in this repo (e.g. `<org>-<repo>-1234`), confirm with the user before assuming.
- Otherwise ask the user for the PR number / URL.

Capture `OWNER`, `REPO`, `PR` once, and reuse them. Verify the PR exists:

```bash
gh pr view <PR> --repo <OWNER>/<REPO> --json number,title,headRefName,baseRefName,state,isDraft,url,body
```

(Capture `body` here too — you'll need it again in Step 5 to decide whether the description needs an update.)

If `gh` reports a missing scope, the user's token is under-scoped. Ask them to refresh:

```
gh auth refresh -h github.com -s repo,read:org
```

(If the token comes from the `GITHUB_TOKEN` env var, `gh auth refresh` is a no-op — the user must replace the env var or `Remove-Item Env:GITHUB_TOKEN; gh auth login -s repo,read:org -w`.)

## Step 2 — Pick scope (which reviewers)

Ask the user upfront:

> "Handle threads from **all reviewers**, or only from one specific reviewer? (Give me a GitHub login if it's just one — e.g. `octocat`, a bot's `author.login`, etc.)"

Capture the answer as `REVIEWER_FILTER` — either the literal string `*` (all reviewers) or a single login. Don't guess and don't default to a particular bot; the same loop is meant to handle Copilot, any other PR-review GitHub App, or a human teammate, and the user's intent is the only signal that picks between them.

If the user gives a reviewer login but isn't sure of the exact spelling, you can list everyone who has commented on the PR's review threads to help them pick:

```bash
gh api graphql -F owner=<OWNER> -F repo=<REPO> -F number=<PR> -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes { comments(first:1) { nodes { author { login } } } }
      }
    }
  }
}' --jq '[.data.repository.pullRequest.reviewThreads.nodes[].comments.nodes[0].author.login] | unique'
```

## Step 3 — List unresolved review threads

Use the GraphQL API. The REST endpoints don't expose `isResolved`.

```bash
gh api graphql -F owner=<OWNER> -F repo=<REPO> -F number=<PR> -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first:20) {
            nodes {
              id
              author { login }
              body
              createdAt
              url
            }
          }
        }
      }
    }
  }
}'
```

Filter the result client-side based on `REVIEWER_FILTER`:

- `select(.isResolved == false)` — only the unresolved ones (always).
- If `REVIEWER_FILTER == "*"` — keep every unresolved thread.
- If `REVIEWER_FILTER` is a specific login — keep only threads whose **first comment** is by that login (i.e. the thread was opened by that reviewer): `select(.comments.nodes[0].author.login == "<login>")`.

In both cases, also surface but do **not** auto-handle threads that already have a non-reviewer reply — those usually represent an in-progress conversation the team intentionally left alone. Treat them as "skip unless the user explicitly asks otherwise".

## Step 4 — For each unresolved thread: fix or won't-fix

For each thread, in order:

1. **Read the file at the referenced `path` and `line`** to see the actual current code (line numbers may have drifted since the comment was posted; always anchor to the current state).
2. **Decide fix or won't-fix** based on:
   - Is the concern still valid against current code? Outdated comments (`isOutdated: true`) often refer to code that no longer exists.
   - Is the suggested fix in scope for the PR? Out-of-scope nits should be won't-fix with explanation, not silently dropped.
   - Does the codebase have established conventions that the reviewer didn't know about? (e.g. "this project uses XYZ pattern, the suggestion conflicts" — won't-fix with explanation).
3. **Apply the fix** using the right tool (Edit / Write / Bash for build/test) and respect repo conventions (resource lookups, `.editorconfig`, lint hooks, etc.).
4. Track the thread → action mapping (in your head or a TaskCreate list) so the reply step has the right context.

### 4a — Classify the comment before acting

Assign one of three labels:

- **BUG / CORRECTNESS** — logic error, null deref, security issue, broken contract.
  → Always fix.
- **CONVENTION** — naming, formatting, import order, pattern consistency.
  → Fix only if the repo's own conventions (`.editorconfig`, linting config, `CLAUDE.md`) agree.
  → If they don't agree, won't-fix with rationale referencing the repo rule.
- **OPINION / STYLE** — subjective preference with no single correct answer, or a suggestion
  that improves aesthetics but not correctness or maintainability.
  → Won't-fix by default. Reply with one sentence acknowledging the idea and explaining
  why the current form is intentional. Do not open a debate.

Surface the classification in your internal tracking list:
`[BUG] path:line — short summary` etc.
Never apply an OPINION fix just because the reviewer is a bot and the fix is mechanical —
bots optimize for their own training signal, not your codebase's coherence.

## Step 5 — Self-review the diff before pushing

Run `git diff --stat` and `git diff` (or per-file `git diff <path>`) on every staged hunk. Walk it and check for:

- Scope creep / unrelated changes.
- Dead code, leftover debug calls, commented-out blocks.
- Copy-paste errors (wrong identifiers, swapped arguments).
- Comments that contradict the new code.
- Build-breaking changes (missing `using`, wrong namespace, typo in a renamed reference).
- Repository convention drift (paired generated files, resource lookups consistent with code, etc.).
- Tests that should accompany the change but are missing.
- Tooling artifacts that shouldn't be committed (e.g. `*.orig` from merge conflict resolution, generated noise from a linter unrelated to your edits — discard those before staging).

If the review surfaces issues, fix them in the **same** commit set rather than letting follow-up commits do "fix the fix". Only after this self-review passes, push.

## Step 6 — Commit and push

Group the fixes into one commit per logical concern (or a single commit if they're related). Use a HEREDOC to keep formatting:

```bash
git add <specific files>
git commit -m "$(cat <<'EOF'
<short title>

<longer rationale: which threads it addresses, why each fix is shaped the way
 it is. Reference thread concerns, not GitHub URLs (those go in the reply).>

Co-Authored-By: <if applicable>
EOF
)"
git push
```

Do not stage with `git add .` or `git add -A` — both can swallow tooling artifacts (`.orig`, build outputs, env files). Stage by explicit path.

## Step 7 — Refresh the PR description

After every push, pull the current PR body and decide whether it still describes the PR accurately. Body drift is the silent killer of code review: reviewers re-read the description on each round, and stale "this PR does X" framing wastes their time.

Fetch:

```bash
gh pr view <PR> --repo <OWNER>/<REPO> --json body --jq '.body'
```

Compare against:

- The list of commits since the original push: `git log --oneline <base>..HEAD`.
- The full diff scope: `git diff --stat <base>..HEAD`.
- Any new files, removed features, scope expansions, scope reductions, or behavioural changes that the description doesn't mention.

Update only if needed. Common triggers:

- The PR's title-level promise has shifted (was about X, now also touches Y).
- The "How to test" section references a path that no longer exists or a flow that changed.
- A risk / out-of-scope note in the description is now stale (the risk was addressed, the deferred work is now included, etc.).
- Screenshots in the description don't reflect the current UI.

To update:

```bash
gh pr edit <PR> --repo <OWNER>/<REPO> --body "$(cat <<'EOF'
<new body>
EOF
)"
```

If the body uses an org template (release notes, test plan, ticket links, PR checklist), preserve the template structure — fill the sections, don't replace them. If unsure whether an edit is needed, surface a one-line diff to the user and ask: low-friction, and avoids gratuitous body churn that just shows up in the review timeline.

## Step 8 — Reply on each thread + resolve

Capture the SHA of the push (`git rev-parse HEAD`) and reference it in each reply so reviewers can navigate to the change.

For each thread, two GraphQL mutations:

```bash
# Reply on the thread
gh api graphql -F threadId=<THREAD_ID> -F body="<reply text>" -f query='
mutation($threadId:ID!, $body:String!) {
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$threadId, body:$body}) {
    comment { url }
  }
}'

# Resolve the thread
gh api graphql -F threadId=<THREAD_ID> -f query='
mutation($threadId:ID!) {
  resolveReviewThread(input:{threadId:$threadId}) {
    thread { isResolved }
  }
}'
```

To **un**resolve (e.g. you want a thread back in the active list because the previous resolution was a mistake), use `unresolveReviewThread` with the same shape.

Reply guidance:

- **Fixed** — name the file and the change shape, reference the commit SHA. Don't paste a 30-line diff; one or two sentences pointing at the commit is enough.
- **Won't fix** — explain *why*: existing convention, out of scope, the concern doesn't apply against current code, etc. Be specific enough that the next reader doesn't need to dig — but tighter than an essay.
- **Side-effect fix** — if you addressed a related but distinct concern in the same commit, call it out so the reviewer doesn't have to reconcile.

## Step 9 — Hand off the re-request to the user

Re-requesting review via the GitHub API is unreliable. The REST `POST /requested_reviewers` endpoint accepts the call and returns `201 Created`, but the request frequently silently no-ops if the reviewer already submitted a review on the latest commit — the read-back of `requested_reviewers` shows the reviewer absent and no notification fires. The GraphQL `requestReviews` mutation has gaps too (rejects Bot IDs entirely). Don't burn cycles trying.

Instead, **ask the user to click the "Re-request review" button** in the GitHub UI, naming the reviewer(s) you handled. Surface the link:

```
https://github.com/<OWNER>/<REPO>/pull/<PR>
```

(The reviewers section on the right has a per-reviewer "Re-request review" circular-arrow icon. The standalone review-requests endpoint `…/pull/<PR>/review-requests` also works.)

Wait for the user to confirm they've re-requested before proceeding to Step 10. **Do not** start polling until you have that confirmation — otherwise the poll loop will run for nothing while the reviewer hasn't been notified.

## Step 10 — Poll for the next review

Capture the baseline so you know when "new" arrives:

- `latestReviewerSubmittedAt` — the most recent `submittedAt` from the reviewer(s) you're tracking, in `reviews(first:50)`.
- `unresolvedCount` — `[reviewThreads.nodes[] | select(.isResolved==false)] | length` (should be 0 right after Step 8).

Then poll. Recommended cadence:

- First 2–3 polls: every ~240s (under the 5-min cache window — keeps your context warm).
- After that: every ~600s up to ~30 minutes total wait.
- Never sleep exactly 300s — that's the worst case (cache miss without amortization). Drop to 240s or commit to 1200s+.

Poll query:

```bash
gh api graphql -F owner=<OWNER> -F repo=<REPO> -F number=<PR> -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes { id isResolved path line comments(first:5) { nodes { author { login } body createdAt } } }
      }
      reviews(first:50) { nodes { author { login } state submittedAt } }
    }
  }
}'
```

Compare the latest matching review's `submittedAt` against your baseline. When it changes:

1. Stop polling.
2. List the new unresolved threads (path, line, brief excerpt of the body), filtered the same way as Step 3.
3. Surface to the user and wait for direction — **do not auto-iterate without a user "go"**, since the user may want to skip this round, change scope, or redirect.

If you've polled 6+ times with no new review, surface that and ask. Don't wait silently forever.

## Loop termination

The loop ends when:

- The reviewer has no new threads after a fresh review pass (review state changes to `APPROVED` or the next review submits with no new unresolved threads), **or**
- The user says to stop / move on, **or**
- The wait cap (~30 minutes) is hit and the user picks a next step.

## Safety notes

- This skill **pushes commits**. Every push happens after a self-review of the diff, but the skill assumes the user has already authorized push-to-branch by invoking it. If the branch is `main` / `master` or a protected branch, **stop and ask** before pushing.
- Replies and thread resolutions are **visible to the team**. Treat them as public communication; no internal jargon, no "this is dumb" framing on won't-fix replies.
- Editing the PR description re-emails the subscribers and shows up in the timeline. Skip the edit if nothing of substance has changed.
- If the reviewer is a human, prefer over-explaining the won't-fix rationale to under-explaining; their next move is to either accept or push back, and a thin reply makes that exchange longer.

## Common pitfalls (from past sessions)

- **Resolving a thread without an explanation** — the team can't tell whether it was fixed, deferred, or ignored. Always reply, even if just one line.
- **Pushing before self-review** — surfaces preventable issues in external review, requiring follow-up "fix the fix" commits. Always run `git diff` before push.
- **Letting the PR description rot** — reviewers re-read it on each round; stale framing inflates review effort. After each push, decide whether the description still matches the code; update if not.
- **Trying to re-request review via the API** — the success response lies; the request often doesn't fire. Always ask the user to do it from the UI, then wait for confirmation before polling.
- **Re-fetching a PR right after a write** — read-after-write on PR object state is unreliable for ~30s. If verification fails immediately, re-check after a beat before assuming the write didn't take.
- **Silently dropping unrelated lint/sync-tool diffs into your commit** — many repos have post-edit tools (formatters, generated-file syncers) that touch unrelated files when triggered. Stage by explicit path so those don't sneak in.
- **Defaulting to a particular reviewer instead of asking** — the same loop is used for bot review, App review, and human review. Always ask the user for scope (Step 2) rather than guessing.
