# Uchujin (宇宙人)

Drop-in, **single-project** error tracker for Rails. In-process capture, ActiveJob/SolidQueue processing, host-delegated auth, a small admin UI, Kamal deploy hooks, uptime probes, and cron check-ins.

No SaaS. No API key. Errors stay in **your** database.

> 宇宙人 (*uchūjin*) — “space person.” Your app’s black-box flight recorder.

**Coming from Honeybadger?** → [docs/vs-honeybadger.md](docs/vs-honeybadger.md) — install comparison, API mapping, dual-run migration, and what does *not* map 1:1.

---

## Why Uchujin

| Need | Uchujin |
|------|---------|
| Track production exceptions without a third party | Yes |
| Group by fingerprint (class + app stack + component) | Yes |
| Dashboard on the same app (`/uchujin`) | Yes |
| Auth via Devise / your admins | Yes |
| Email when something new blows up | Yes |
| Deploy markers + cron heartbeats | Yes |
| Multi-app org console / hosted APM | No — use Honeybadger or similar |

---

## Features

- **In-process capture** — Rack middleware + `Rails.error` subscriber + ActiveJob rescue
- **Fingerprinted faults** — exception class + cleaned app backtrace + component
- **Occurrences** — full backtrace, source context, breadcrumbs, request/params, server stats
- **Admin UI** at `/uchujin` — dashboard, search (`is:unresolved environment:production`), resolve/ignore, comments
- **Host auth** — you wire `authenticate_user!`; Uchujin does not ship users
- **Notifications** — email (rate-limited)
- **Deploy tracking** — `POST /uchujin/api/deployments` (Bearer token)
- **Uptime checks** — `Uchujin::UptimeCheckJob`
- **Cron check-ins** — heartbeat pings with overdue detection
- **Retention** — optional `Uchujin::PruneJob`

---

## Requirements

- Ruby ≥ 3.2  
- Rails ≥ 7.1  
- ActiveJob backend (SolidQueue, Sidekiq, async, …) so notices persist off the request thread  

---

## Installation

```ruby
# Gemfile
gem "uchujin", github: "cmbaldwin/Uchujin"
```

```bash
bundle install
bin/rails generate uchujin:install
bin/rails db:migrate
```

The install generator:

1. Adds the migration for `uchujin_*` tables  
2. Creates `config/initializers/uchujin.rb`  
3. Mounts the engine at `/uchujin`  

### Initializer (minimum for production)

```ruby
# config/initializers/uchujin.rb
Uchujin.configure do |config|
  # Required: do not leave the UI open on the public internet
  config.authenticate do
    authenticate_user! # Devise — or authenticate_admin!, etc.
  end

  config.current_user_method { current_user }

  config.app_name = "My App"
  config.environments = %w[production staging]

  config.notification_email = "ops@example.com"
  config.deploy_token = ENV["UCHUJIN_DEPLOY_TOKEN"]
  config.revision = ENV["KAMAL_VERSION"] || ENV["GIT_REVISION"]
end
```

Routes (added by the generator):

```ruby
# config/routes.rb
mount Uchujin::Engine => "/uchujin"
```

Open **`/uchujin`** while signed in as an allowed host user.

---

## Usage

Capture is automatic for unhandled web and job exceptions (in configured environments).

### Manual capture

```ruby
begin
  risky!
rescue => e
  Uchujin.notify(e, context: { order_id: order.id }, component: "checkout")
  raise
end

Uchujin.context(user_id: current_user.id)
Uchujin.leave_breadcrumb("payment.started", type: "custom", metadata: { amount: 1200 })
```

### Honeybadger-style search

| Token | Meaning |
|-------|---------|
| `is:unresolved` / `is:resolved` / `is:ignored` | Status filter |
| `-is:resolved` | Negation |
| `is:assigned` | Has assignee |
| `environment:production` | Environment |
| `component:job` | Component |
| `tag:payments` | Tag |
| free text | Class name / message |

### Deploy hook (Kamal / CI)

```bash
curl -X POST https://app.example.com/uchujin/api/deployments \
  -H "Authorization: Bearer $UCHUJIN_DEPLOY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sha":"'"$KAMAL_VERSION"'","environment":"production","user":"kamal"}'
```

### Check-ins (cron heartbeats)

```bash
curl -X POST https://app.example.com/uchujin/api/check_ins/nightly-backup/ping \
  -H "Authorization: Bearer $UCHUJIN_DEPLOY_TOKEN"
```

### Uptime + prune (schedule with SolidQueue / cron)

```ruby
Uchujin::UptimeCheckJob.perform_later(["https://app.example.com/up"])
# or set ENV UCHUJIN_UPTIME_URLS=https://app.example.com/up

# config.pruning_enabled = true
Uchujin::PruneJob.perform_later
```

---

## Configuration reference

| Option | Default | Purpose |
|--------|---------|---------|
| `authenticate` | none | `before_action` block for all UI controllers |
| `current_user_method` | none | User for comments / assignee helpers |
| `environments` | dev, production, staging | Capture only in these envs |
| `ignored_exceptions` | RoutingError, RecordNotFound, … | Skip notify |
| `breadcrumb_limit` | 50 | Ring buffer size |
| `source_context_lines` | 5 | Source snippet window |
| `revision` | `GIT_REVISION` / Kamal / Heroku env | Attach to faults |
| `deploy_token` | `UCHUJIN_DEPLOY_TOKEN` | API Bearer for deploys & check-ins |
| `notification_email` | nil | Mailer recipient |
| `notify_on_every_occurrence` | false | If true, skip “resolved only / rate limit” quieting |
| `notification_rate_limit` | 5 minutes | Per-fault notify throttle |
| `pruning_enabled` | false | Allow `PruneJob` to delete |
| `retention_period` | 90 days | Old occurrences |
| `resolved_retention_period` | 30 days | Resolved/ignored faults |
| `app_name` | `"Uchujin"` | UI + email subject |

---

## Architecture (short)

```
Exception
  → Middleware / Rails.error / ActiveJob rescue
  → Uchujin.notify (build notice Hash)
  → ProcessNoticeJob (ActiveJob)
  → Fault (fingerprint) + Occurrence rows
  → Notifier (email, rate-limited)
  → UI at /uchujin
```

Nothing is sent to an external error SaaS for capture.

---

## Docs

| Doc | Contents |
|-----|----------|
| [docs/vs-honeybadger.md](docs/vs-honeybadger.md) | Drop-in vs Honeybadger install, API map, dual-run, gaps |
| [CHANGELOG.md](CHANGELOG.md) | Releases |

---

## Development

```bash
cd Uchujin
bundle install
bundle exec rake app:db:prepare
bundle exec rails test
```

## License

MIT © Cody Baldwin
