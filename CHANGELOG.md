# Changelog

## Unreleased

## 0.2.1 — 2026-09-10

- **Deps:** bump `rails` 8.1.3 → 8.1.3.1, `sqlite3` 2.9.5 → 2.9.6, GHA `actions/checkout` 6→7, `actions/cache` 4→6, `actions/upload-artifact` 4→7
- **Spark audit fixes (5):** `check_ins` cadence sanitization (ignore non-numeric `expected_every_seconds`), `deployments` garbage `deployed_at` fallback to `Time.current`, MCP Bearer case-insensitive (keep `X-Uchujin-Token`), `PruneJob` single-SQL `occurrences_count` repair (remove N+1), `JobErrorHandling` clear breadcrumbs/context per job
- **Docs:** add `docs/AUDIT-OX-2026-08.md`, `docs/SPARK-AUDIT-2026-09.md`, `docs/research/rails-error-trackers-2026.md`, and `docs/plans/001`–`006` (storm, locals, capture-hooks, dashboard, MCP, github-workflow) — plans remain docs-only, not yet implemented

## 0.2.0 — 2026-07-12

- **MCP server** for AI agents at `POST /uchujin/api/mcp` (JSON-RPC tools).
  - Enable with `config.mcp_enabled = true` and `config.mcp_token` (falls back to `deploy_token`).
  - Full triage tools: list/search/get faults & occurrences, resolve/ignore/reopen/assign/update/comment, bulk actions, delete, deploys, check-ins, uptime, stats.
  - Docs: [docs/MCP.md](docs/MCP.md)

## 0.1.2 — 2026-07-12

Found during host-integration audit:

- **Breaking:** remove Slack and generic webhook notification paths (`slack_webhook_url`, `webhook_url`). Host integrations weren't using them; email notifications are unaffected.
- Fix double occurrence capture: one unhandled exception could be reported twice (middleware + `Rails.error` subscriber for web; `around_perform` + `Rails.error` for jobs). `Uchujin.notify` now tags the exception object after the first report and short-circuits on a second call with the same object. Retried jobs raise new exception objects per attempt, so retries are still captured.
- Fix `uchujin_notifications` rows never being pruned — `PruneJob` now deletes notifications older than `retention_period` alongside occurrences.

## 0.1.1 — 2026-07-11

Production hardening before first host integration:

- Stop double-running migrations (install generator only; no engine path append)
- Fail-closed UI auth in production when `config.authenticate` is unset
- PostgreSQL-safe `tag:` search (`CAST(tags AS TEXT) LIKE`)
- Dedup concurrent capture via thread reentrancy flag
- Jobs use configurable `queue_name` (default `:default`)
- `create_or_find_by!` for fingerprint races
- `around_perform` job capture (plays nicer with `retry_on`)
- Thread-local breadcrumb clock; `mailer_from` separate from notify To:

## 0.1.0 — 2026-07-11

Initial public release.

- Mountable Rails engine with host-delegated auth
- Error capture via middleware, `Rails.error`, and ActiveJob
- Fingerprinted faults + occurrence detail (backtrace, source context, breadcrumbs)
- Admin UI: dashboard, faults, deploys, uptime, check-ins
- Notifications: email, Slack, webhook (rate-limited)
- Deploy API + check-in ping API (Bearer deploy token)
- Install generator, prune job, uptime job
