# Uchujin (宇宙人)

Drop-in, single-project error tracker for Rails. In-process capture, SolidQueue/ActiveJob processing, host-delegated auth, Tailwind-free admin UI, Kamal deploy hooks, uptime probes, and cron check-ins. No SaaS.

> 宇宙人 (*uchūjin*) — “space person.” Your app’s black-box flight recorder.

## Features

- **In-process capture** — Rack middleware + `Rails.error` subscriber + ActiveJob rescue
- **Fingerprinted faults** — groups by exception class + cleaned app backtrace + component
- **Occurrences** — full backtrace, source context, breadcrumbs, request/params, server stats
- **Admin UI** at `/uchujin` — dashboard, search (`is:unresolved environment:production`), resolve/ignore, comments
- **Host auth** — you wire Devise/`authenticate_admin!`; Uchujin does not ship users
- **Notifications** — email, Slack webhook, generic webhook (rate-limited)
- **Deploy tracking** — `POST /uchujin/api/deployments` (Bearer token)
- **Uptime checks** — `Uchujin::UptimeCheckJob`
- **Cron check-ins** — heartbeat pings with overdue detection
- **Retention** — optional `Uchujin::PruneJob`

## Requirements

- Ruby ≥ 3.2
- Rails ≥ 7.1
- ActiveJob backend (SolidQueue, Sidekiq, async, etc.)

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

### Initializer

```ruby
# config/initializers/uchujin.rb
Uchujin.configure do |config|
  config.authenticate do
    authenticate_user! # or authenticate_admin!
  end

  config.current_user_method { current_user }

  config.app_name = "Ako Tacos"
  config.environments = %w[production staging]
  config.notification_email = "ops@example.com"
  config.slack_webhook_url = ENV["UCHUJIN_SLACK_WEBHOOK"]
  config.deploy_token = ENV["UCHUJIN_DEPLOY_TOKEN"]
  config.revision = ENV["KAMAL_VERSION"] || ENV["GIT_REVISION"]
end
```

Mount (added by the generator):

```ruby
# config/routes.rb
mount Uchujin::Engine => "/uchujin"
```

## Usage

Capture is automatic for unhandled web and job exceptions. Manual capture:

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

### Deploy hook (Kamal)

```bash
curl -X POST https://app.example.com/uchujin/api/deployments \
  -H "Authorization: Bearer $UCHUJIN_DEPLOY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sha":"'"$KAMAL_VERSION"'","environment":"production","user":"kamal"}'
```

### Check-ins

```bash
curl -X POST https://app.example.com/uchujin/api/check_ins/nightly-backup/ping \
  -H "Authorization: Bearer $UCHUJIN_DEPLOY_TOKEN"
```

### Uptime + prune (recurring)

```ruby
# e.g. SolidQueue recurring / whenever
Uchujin::UptimeCheckJob.perform_later(["https://app.example.com/up"])
Uchujin::PruneJob.perform_later  # when config.pruning_enabled = true
```

## Search syntax

| Token | Meaning |
|-------|---------|
| `is:unresolved` / `is:resolved` / `is:ignored` | Status filter |
| `-is:resolved` | Negation |
| `is:assigned` | Has assignee |
| `environment:production` | Environment |
| `component:job` | Component |
| `tag:payments` | Tag (JSON) |
| free text | Class name / message `LIKE` |

## Development

```bash
cd Uchujin
bundle install
cd test/dummy && bin/rails db:prepare && cd ../..
bin/rails test
```

## License

MIT © Cody Baldwin
