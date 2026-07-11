# Changelog

## Unreleased

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
