# Plan: Local (and optional instance) variable capture

**Priority:** P1  
**Inspired by:** Faultline “Debugger Inspector”, rails_error_dashboard locals, Sentry paid locals  
**Status:** Plan only

## Problem

Stack frames + source context show *where* it broke; they often don’t show *what values* were wrong (`order_id`, `nil` user, empty cart). Operators open a console and re-guess.

## Goals

1. Capture **local variables** for the top N application frames when possible.
2. Store on `uchujin_occurrences` as JSON; render in fault UI (collapsible, per frame).
3. **Never** capture secrets: filter keys via `Rails.application.config.filter_parameters` + Uchujin blocklist.
4. **Safe by default:** off in production until enabled; hard size limits; rescue everything.

## Non-goals

- Full debugger / binding.break integration.
- Capturing every frame’s locals (too heavy, too leaky).

## Design sketch

### Capture strategy (pick one for v1)

**Option A — `Exception#binding` (MRI)**  
On modern Ruby, some exceptions expose bindings; not reliable for all raise paths.

**Option B — TracePoint `:raise` (recommended for v1)**  
Optional subscriber when `config.capture_locals = true`:

```ruby
TracePoint.new(:raise) do |tp|
  next unless Thread.current[:uchujin_capture_locals]
  # store tp.binding.local_variables → values (filtered, truncated)
end
```

Only enable around capture paths, or always-on with ring buffer of last raise binding (careful with cost).

**Option C — `debug` gem / `ErrorHighlight` + manual**  
Less automatic.

Recommend **B with sampling**: only attach TracePoint when config enabled; store last raise locals on Thread for the exception object id.

### Storage

```ruby
# migration add to uchujin_occurrences
t.json :locals, default: {}
# shape: { "app/models/order.rb:42" => { "id" => 1, "status" => "paid" }, ... }
```

### Filtering

```ruby
FILTER = ActiveSupport::ParameterFilter.new(
  Rails.application.config.filter_parameters + %i[password token secret api_key card]
)
# also drop objects that are huge / IO / AR relations → summarize as "#<Order id:1>"
```

### UI

On fault show, under application stack:

```
app/models/order.rb:42 in `charge!`
  id: 99102
  amount_cents: 1200
  user_id: nil    ← highlight nils?
```

### Config

```ruby
config.capture_locals = false          # default off until battle-tested
config.locals_max_frames = 3
config.locals_max_value_bytes = 200
config.locals_max_keys_per_frame = 30
```

### Risks

- **PII leakage** in emails if locals included in mailer — **exclude locals from email**, UI only.
- Performance: TracePoint cost — measure; disable under storm protection (ties to plan 001).
- Thread safety of TracePoint enable/disable.

## Implementation steps

1. Spike TracePoint approach in dummy app; document Ruby version support.
2. `Uchujin::LocalsCapture` + filter helpers.
3. Migration + model + ProcessNoticeJob wire-up.
4. View partial.
5. Tests with a controlled raise that has interesting locals.
6. Security note in README.

## Acceptance

- [ ] With flag on, a deliberate raise shows filtered locals in UI
- [ ] Password-like keys redacted
- [ ] Flag off = zero TracePoint / zero column use
- [ ] Storm mode skips locals

## References

- Faultline “Local Variables Capture” / Debugger Inspector
- rails_error_dashboard free locals + instance vars
