# Rails error tracking landscape (2026) — research for Uchujin

Researched: 2026-07-12. Context: Uchujin v0.1.2 (in-process engine, email-only notify, fingerprint grouping, deploys/check-ins/uptime). Host: single-app Rails 8 (e.g. akotacos).

## Competitors reviewed

| Product | Model | Closest to Uchujin? |
|---------|--------|---------------------|
| **Honeybadger** | SaaS Ruby/Rails-native | API/UX patterns we already mirror |
| **Sentry** | SaaS multi-lang + browser | Overkill; profiling/replay out of scope |
| **AppSignal** | SaaS APM + errors | APM-first; not our lane |
| **Errbit** | Self-hosted Airbrake-compat (Mongo) | Separate app, not embeddable |
| **[Faultline](https://github.com/dlt/faultline)** | Embeddable Rails 8 engine | **Yes** — same niche |
| **[rails_error_dashboard](https://github.com/AnjanJ/rails_error_dashboard)** | Embeddable engine, very active | **Yes** — richest peer |
| Telebugs | Self-hosted Sentry-compatible | External process |

Uchujin’s niche remains: **single-project, in-process, no SaaS, no extra DB (optional), host auth, Kamal-friendly**. We deliberately dropped Slack/webhook in v0.1.2 — keep email (+ optional future pluggable notifiers only if host asks).

## Feature gap matrix (relative to Uchujin 0.1.2)

| Feature | HB | Sentry | Faultline | RED | Uchujin | Plan PR? |
|---------|----|--------|-----------|-----|---------|----------|
| Fingerprint grouping | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| Breadcrumbs (AS notifications) | ✓ | ✓ | partial | ✓ | ✓ | — |
| Deploy markers | ✓ | ✓ (releases) | ? | ? | ✓ | — |
| Cron check-ins | ✓ | ✓ | — | — | ✓ | — |
| Uptime probes | ✓ | — | — | — | ✓ | — |
| Email notify + rate limit | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| **Storm protection / sampling** | cloud | cloud | ? | **strong** | — | **Yes — P0** |
| **Local vars at raise** | paid tier | paid tier | **✓** | **✓** | — | **Yes — P1** |
| **before_notify / filter hooks** | ✓ | ✓ | partial | ✓ | ignore list only | **Yes — P1** |
| **User / CurrentAttributes context** | ✓ | ✓ | ✓ | ✓ | manual only | **Yes — P1** |
| **Dashboard charts / spikes** | ✓ | ✓ | ✓ | ✓ | counts only | **Yes — P2** |
| **Mute / snooze / batch** | ✓ | ✓ | status | ✓ | resolve/ignore | **Yes — P2** |
| **GitHub issue from fault** | ✓ | ✓ | ✓ | ✓ | — | **Yes — P2** |
| **MCP for AI debugging** | — | — | **✓** | AI panel | — | **Yes — P2** |
| Full APM / flame graphs | Insights | ✓ | experimental | N+1 | — | **No** (scope creep) |
| Session replay | — | ✓ | — | — | — | **No** |
| Multi-app org | ✓ | ✓ | — | multi | — | **No** |
| Browser JS SDK | ✓ | ✓ | — | — | — | **No** (later) |

## What we should **not** chase

- Session replay, distributed tracing product surface, host metrics APM (AppSignal/Sentry lane).
- Re-adding Slack/Discord as first-class (explicitly removed v0.1.2); hosts can watch email or build a thin host job on `Notification` if needed.
- Mongo Errbit-style separate deploy — wrong packaging for Kamal single-app.

## Priority order for Uchujin plans

1. **P0 Storm protection** — in-process trackers can DDoS their own DB during a bad deploy. RED’s design is the gold standard here.
2. **P1 Capture quality** — locals, `before_notify`, user/CurrentAttributes, scrubbing.
3. **P2 Operator workflow** — charts, mute/snooze, batch, GitHub issues.
4. **P2 AI assist** — MCP tools over fault data (Faultline pattern; fits Escalante/Claude workflow).

Individual plans live under [`docs/plans/`](../plans/).
