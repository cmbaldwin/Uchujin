# Uchujin vs Honeybadger — drop-in guide

This guide is for Rails apps that use (or would use) [Honeybadger](https://www.honeybadger.io/) and want an **in-process, self-hosted** alternative with no SaaS account, no API key, and no outbound error traffic.

Uchujin is **not** a wire-compatible Honeybadger client. Capture APIs are intentionally small and familiar; the UI and ops model are different (your DB, your auth, your `/uchujin` mount).

---

## Philosophy

| | Honeybadger | Uchujin |
|---|---|---|
| Where errors live | Honeybadger’s cloud | **Your app’s database** (`uchujin_*` tables) |
| Dashboard | app.honeybadger.io | **`/uchujin` on your app** |
| Auth | Honeybadger team login | **Host app** (Devise, etc.) |
| Network | HTTPS notify to HB | **None** for capture (in-process + ActiveJob) |
| Multi-project | One HB account, many projects | **One install per Rails app** |
| Billing | SaaS plan | Free (you pay disk + ops) |
| Uptime / check-ins | HB products | Built-in jobs + API pings |
| Insights / APM | HB Insights, etc. | **Not included** — errors + deploys + heartbeats only |

Use Honeybadger when you want a managed multi-app console, SLAs, and zero ops. Use Uchujin when you want errors to stay on the same server as the app (privacy, cost, air-gapped, Kamal single-box).

---

## Side-by-side install

### Honeybadger (typical)

```ruby
# Gemfile
gem "honeybadger"
```

```bash
bundle install
# Set API key (env or config/honeybadger.yml)
export HONEYBADGER_API_KEY=xxxxxxxx
# Optional generator
bin/rails generate honeybadger --api-key=xxxxxxxx
```

```yaml
# config/honeybadger.yml (common pattern)
---
api_key: "<%= ENV['HONEYBADGER_API_KEY'] %>"
exceptions:
  ignore:
    - "ActionController::RoutingError"
```

No migrations. No mount. Dashboard is external.

### Uchujin (drop-in)

```ruby
# Gemfile
gem "uchujin", github: "cmbaldwin/Uchujin"
# or after publish: gem "uchujin"
```

```bash
bundle install
bin/rails generate uchujin:install
bin/rails db:migrate
```

The generator:

1. Copies a migration (`uchujin_faults`, `uchujin_occurrences`, …)
2. Creates `config/initializers/uchujin.rb`
3. Mounts the engine: `mount Uchujin::Engine => "/uchujin"`

```ruby
# config/initializers/uchujin.rb
Uchujin.configure do |config|
  # Gate the UI — this replaces “log into Honeybadger”
  config.authenticate do
    authenticate_user! # Devise; or authenticate_admin!
  end
  config.current_user_method { current_user }

  config.app_name = "My App"
  config.environments = %w[production staging] # skip test by default in library defaults

  # Replaces HB project alerts (email)
  config.notification_email = ENV["UCHUJIN_NOTIFY_EMAIL"]

  # Replaces HB deploy API key usage for your hooks
  config.deploy_token = ENV["UCHUJIN_DEPLOY_TOKEN"]
  config.revision = ENV["KAMAL_VERSION"] || ENV["GIT_REVISION"]
end
```

**Requirements Honeybadger does not need:**

- ActiveJob backend (SolidQueue, Sidekiq, …) so `ProcessNoticeJob` can persist notices async
- Disk/DB for fault history
- Auth on `/uchujin` (do not leave it open in production)

---

## API mapping (code you already wrote)

### Notify / report an exception

```ruby
# Honeybadger
Honeybadger.notify(exception)
Honeybadger.notify(exception, context: { order_id: order.id })
Honeybadger.notify("Something went wrong") # string notices

# Uchujin
Uchujin.notify(exception)
Uchujin.notify(exception, context: { order_id: order.id }, component: "checkout")
# String-only notices are not supported — pass an Exception
```

### Request / user context

```ruby
# Honeybadger
Honeybadger.context({ user_id: current_user.id, plan: "pro" })

# Uchujin
Uchujin.context(user_id: current_user.id, plan: "pro")
# merges into the next notify for this request/job (thread-local)
```

### Breadcrumbs

```ruby
# Honeybadger
Honeybadger.add_breadcrumb("Checkout started", category: "custom", metadata: { cart_id: id })

# Uchujin
Uchujin.leave_breadcrumb("Checkout started", type: "custom", metadata: { cart_id: id })
```

SQL + controller breadcrumbs are recorded automatically (similar spirit to HB request trail).

### Ignore exceptions

```yaml
# Honeybadger — honeybadger.yml
exceptions:
  ignore:
    - ActionController::RoutingError
    - ActiveRecord::RecordNotFound
```

```ruby
# Uchujin — initializer
config.ignored_exceptions = %w[
  ActionController::RoutingError
  ActiveRecord::RecordNotFound
  AbstractController::ActionNotFound
]
```

### Environments

```yaml
# Honeybadger
# report_data / env-specific keys in yml
```

```ruby
# Uchujin — only these envs enqueue notices
config.environments = %w[production staging]
```

### Manual rescue pattern

Both work the same idea:

```ruby
begin
  risky!
rescue => e
  Uchujin.notify(e, context: { step: "charge" })  # was Honeybadger.notify(e, …)
  raise
end
```

### What you can delete after switching

| Remove | Notes |
|--------|--------|
| `gem "honeybadger"` | After dual-running if you want a transition period |
| `config/honeybadger.yml` | |
| `HONEYBADGER_API_KEY` | |
| `Honeybadger.notify` / `.context` / breadcrumbs | Replace with `Uchujin.*` |
| HB JS / frontend notifier | Uchujin is **server-side only** today |

---

## Deploy tracking

### Honeybadger

```bash
# Common CI / deploy step
curl https://api.honeybadger.io/v1/deploys \
  -d api_key=$HONEYBADGER_API_KEY \
  -d deploy[environment]=production \
  -d deploy[revision]=$GIT_SHA \
  -d deploy[local_username]=deploy
```

### Uchujin

```bash
curl -X POST https://your-app.example/uchujin/api/deployments \
  -H "Authorization: Bearer $UCHUJIN_DEPLOY_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"sha\":\"$KAMAL_VERSION\",\"environment\":\"production\",\"user\":\"kamal\"}"
```

Kamal example (after deploy):

```yaml
# config/deploy.yml (illustrative)
# run a post-deploy curl with UCHUJIN_DEPLOY_TOKEN from secrets
```

Deploys show under **Deploys** in `/uchujin` and can be correlated with faults first seen near that window.

---

## Check-ins / cron heartbeats

Honeybadger Check-Ins use a HB-hosted ping URL.

Uchujin:

```bash
# Register expected interval in UI, or first ping creates the name
curl -X POST https://your-app.example/uchujin/api/check_ins/nightly-backup/ping \
  -H "Authorization: Bearer $UCHUJIN_DEPLOY_TOKEN"
```

Overdue check-ins surface on the dashboard when `expected_every_seconds` is set.

---

## Uptime

Honeybadger Uptime is a separate cloud product.

Uchujin schedules probes **from your app**:

```ruby
# SolidQueue recurring / cron
Uchujin::UptimeCheckJob.perform_later(["https://your-app.example/up"])
# or ENV UCHUJIN_UPTIME_URLS=https://a.example/up,https://b.example/up
```

Results live in `/uchujin/uptime_checks`. This is simple HTTP GET status — not a full synthetic multi-region product.

---

## Alerts

| Honeybadger | Uchujin |
|-------------|---------|
| Project → Alerts (email, Slack, PagerDuty, …) | `notification_email` |
| Smart throttle in product | `notification_rate_limit` (default 5 minutes per fault) |
| Per-env / per-error rules | Rate limit + ignore list + resolve/ignore in UI |

```ruby
config.notification_email = "ops@example.com"
config.notify_on_every_occurrence = false
config.notification_rate_limit = 5.minutes
```

---

## Dashboard & workflow

| Task | Honeybadger | Uchujin |
|------|-------------|---------|
| Open inbox | honeybadger.io | `https://your-app/uchujin` |
| Search | HB search / filters | `is:unresolved environment:production tag:payments` |
| Resolve / ignore | HB UI | Fault show → Resolve / Ignore / Reopen |
| Comment | HB comments | Comments on fault (author from host user) |
| Assign | HB assignees | `assignee_id` (host user id) |
| Multi-app switcher | HB projects | **N/A** — install gem per app |

Search tokens (Honeybadger-inspired):

| Token | Meaning |
|-------|---------|
| `is:unresolved` / `is:resolved` / `is:ignored` | Status |
| `-is:resolved` | Negation |
| `is:assigned` | Has assignee |
| `environment:production` | Env |
| `component:job` | Component (`web`, `job`, …) |
| `tag:payments` | Tag |
| free text | Class / message |

---

## Dual-run migration (recommended)

Run both for a week so you do not drop coverage:

1. Install Uchujin (migrate, auth, mount).
2. Keep `Honeybadger.notify` paths; also call `Uchujin.notify` only where you notify manually — **or** rely on both auto-capture stacks (middleware may double-capture unhandled errors into both systems; that is usually fine during transition).
3. Compare fault counts in `/uchujin` vs HB.
4. Point email alerts at Uchujin; disable HB alerts.
5. Remove the honeybadger gem and API key.

For **only** unhandled exceptions, both gems’ middleware can coexist; you will see the same exception in both UIs until you remove one.

---

## What Uchujin does **not** replace

- Honeybadger **Insights** / performance APM  
- Browser / mobile SDKs and source maps  
- Multi-project org dashboard  
- Advanced alert routing (PagerDuty depth, escalation policies)  
- Hosted multi-region uptime  
- Long-term storage without your own retention job  

Retention on Uchujin:

```ruby
config.pruning_enabled = true
config.retention_period = 90.days
config.resolved_retention_period = 30.days
# schedule daily:
Uchujin::PruneJob.perform_later
```

---

## Checklist: “drop in” for a single Rails app

- [ ] Add gem, `uchujin:install`, `db:migrate`
- [ ] `config.authenticate` so `/uchujin` is not public
- [ ] ActiveJob worker running in production
- [ ] `config.environments` matches where you want capture
- [ ] Optional: email notify
- [ ] Optional: deploy hook with `UCHUJIN_DEPLOY_TOKEN`
- [ ] Optional: check-in pings for cron jobs
- [ ] Optional: uptime job + prune job on a schedule
- [ ] Remove Honeybadger when satisfied

---

## Quick reference

```ruby
# Capture
Uchujin.notify(exception, context: {}, component: "web")
Uchujin.context(user_id: 1)
Uchujin.leave_breadcrumb("step", type: "custom", metadata: {})

# Config keys of interest
# authenticate, current_user_method, environments, ignored_exceptions,
# notification_email, deploy_token,
# revision, pruning_enabled, retention_period, notification_rate_limit
```

```text
UI:     /uchujin
Deploys POST /uchujin/api/deployments
Ping    POST /uchujin/api/check_ins/:name/ping
```

For full install details see the root [README](../README.md).
