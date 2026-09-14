# webreq file formats

Root folder (set by `init`, stored in `~/.claude/webreq.json`, overridable with env `WEBREQ_ROOT`):

```
<root>/
  .gitignore              # ignores contexts/*.local.json
  contexts/
    staging.json          # shared, committed
    staging.local.json    # secrets overlay, gitignored, deep-merged over staging.json
  collections/
    billing.json          # one file = one collection of requests
```

## Context (`contexts/<name>.json`)
Flat or nested JSON. Every key becomes a template variable. Keys are free; use the same names across contexts so requests stay portable.

```json
{
  "baseUrl": "https://api.staging.example.com",
  "accountId": "acme",
  "tenantId": "default",
  "token": "${env:STAGING_TOKEN}"
}
```

`${env:NAME}` is replaced with the environment variable at run time. Keys matching token/secret/password/apikey/auth are masked in output and written to `.local.json` by `set` unless `--shared`.

## Collection (`collections/<id>.json`)

```json
{
  "description": "Billing service",
  "headers": { "Authorization": "Bearer {{token}}", "X-Tenant-Id": "{{tenantId}}" },
  "vars": { "apiVersion": "v1" },
  "requests": [
    {
      "name": "list-invoices",
      "description": "List invoices of a given status for a tenant",
      "tags": ["billing", "invoices", "list"],
      "method": "GET",
      "url": "{{baseUrl}}/{{accountId}}/{{tenantId}}/{{apiVersion}}/invoices?status={{status}}",
      "vars": { "status": { "description": "invoice status, e.g. open" }, "top": { "default": 50 } }
    },
    {
      "name": "create-invoice",
      "description": "Create an invoice",
      "method": "POST",
      "url": "{{baseUrl}}/{{accountId}}/{{tenantId}}/{{apiVersion}}/invoices",
      "headers": { "Content-Type": "application/json" },
      "body": { "status": "{{status}}", "customer": "{{customer}}", "amount": "{{amount}}" }
    }
  ]
}
```

- `headers` on the collection apply to every request; request `headers` override per key.
- `body` may be an object (sent as JSON) or a string. Templates are rendered inside both; a variable that is itself an object is inlined as JSON.
- `vars` documents variables the request needs. Only `default` affects execution; `description` is for the agent/user.
- Variable precedence: `-v` overrides > request `vars.*.default` > collection `vars` > context.
- `{{a.b}}` reaches into nested context objects.

## Run output
Line 1: `<status> <statusText> <ms> <METHOD> <url>`; then the body compacted to one line, truncated at `--max` (default 2000 chars). `--pick data.items[0].id` extracts a path; `--out file` saves the raw body; `--dry` prints the resolved request without sending. Exit codes: 0 ok, 1 usage/config, 2 HTTP error status, 3 unresolved variables.
