---
name: webreq
description: Run, store and organize HTTP requests as templated collections with per-environment contexts (base URL, bearer, account/tenant ids), kept in a user-chosen repo folder. Use when the user wants to call, test or try an API / service / endpoint, "call X in alpha/staging/prod", save a request for reuse, create a request collection or context, or asks what requests are available.
---

# webreq

Runner: `node <this skill dir>/scripts/webreq.mjs <command>` (no deps). Run `help` for the full command list.
All definitions live in the user's root folder (`contexts/`, `collections/`), configured once via `init`.

## First use
If `root` fails: ask where the requests repo folder should be, then `init <folder>`.

## Free-text request ("call the billing service in staging for open invoices, tenant xxx")
1. `list <keywords>` with 1-3 words from the sentence (service, resource, verb). Pick the single obvious match; if several fit, ask which.
2. Context = the environment word (alpha, staging, prod...). Check `contexts` if unsure. If none named and only one context exists, use it.
3. Values in the sentence become `-v name=value` overrides (tenant id, entity type, ids). Do not guess unknown values.
4. `run <col>/<req> -c <ctx> -v k=v ...`. Show the user status + the relevant part of the body. Use `--pick` / `--max` / `--out` to keep output small.
5. No match in step 1: propose a request definition (see REFERENCE.md), confirm URL/method with the user, save with `add`, then run it.

## Ask the user when data is missing (never invent it)
- exit 3 `unresolved vars` -> ask for each missing value. Persist environment-level values with `set <ctx> k=v`; per-call values just go in `-v`.
- 401/403 -> ask for a valid bearer (or how to obtain one), then `set <ctx> token=<value>` (lands in `<ctx>.local.json`, gitignored) and re-run.
- 404 with a plausible URL -> ask whether the path/ids are right before editing the definition.

## Creating a context
Ask, in one message: name (alpha/prod...), base URL, how auth works (bearer value, env var, or none), and the ids the service needs (accountId, tenantId, orgId...). Then `set <name> baseUrl=... accountId=...` and `set <name> token=...` (secrets auto-route to the local overlay; use `token=${env:VAR}` to reference an env var). Verify with `context <name>`.

## Creating / editing requests
Prefer generic templates (`{{tenantId}}`, `{{entityType}}`) over hard-coded values so one definition serves every context. Write a one-line `description` and `tags` that a future free-text request would match. Formats: [REFERENCE.md](REFERENCE.md).

## Keep tokens low
Use `list` not `show` to find requests; run with `--pick` for large payloads; never `--full` unless asked; `--dry` to preview a resolved request instead of explaining it.
