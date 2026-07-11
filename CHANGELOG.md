# Changelog

## Unreleased

- Expanded README and added [docs/vs-honeybadger.md](docs/vs-honeybadger.md) (Honeybadger drop-in comparison).

## 0.1.0 — 2026-07-11

Initial public release.

- Mountable Rails engine with host-delegated auth
- Error capture via middleware, `Rails.error`, and ActiveJob
- Fingerprinted faults + occurrence detail (backtrace, source context, breadcrumbs)
- Admin UI: dashboard, faults, deploys, uptime, check-ins
- Notifications: email, Slack, webhook (rate-limited)
- Deploy API + check-in ping API (Bearer deploy token)
- Install generator, prune job, uptime job
