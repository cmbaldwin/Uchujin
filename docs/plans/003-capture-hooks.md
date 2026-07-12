# Plan: Capture hooks — before_notify, filters, fingerprint, user context

**Priority:** P1  
**Inspired by:** Honeybadger (`before_notify`, context, user), Sentry (`before_send`, fingerprint), RED (`CurrentAttributes`)  
**Status:** Plan only

## Problem

Hosts need to:

- Drop noisy exceptions not worth a class-name ignore list  
- Scrub/enrich context  
- Override fingerprint when default grouping is wrong  
- Auto-attach `current_user` without manual `Uchujin.context` every action  

Today: `ignored_exceptions` class names only + manual `Uchujin.context`.

## Goals

1. **`before_notify` chain** — callables receive a mutable notice hash (or Notice object); return `false` / `:skip` to drop.
2. **Custom fingerprint** — optional proc `(exception, notice) -> String`.
3. **Auto user context** — host provides `config.user_context { |req| { id:, email: } }` or integrate `ActiveSupport::CurrentAttributes`.
4. **ParameterFilter** already used for params; extend to context keys recursively.

## Non-goals

- Multi-project routing.
- Changing the public `Uchujin.notify` signature incompatibly (only additive kwargs).

## Design sketch

### Notice object (optional thin wrapper)

```ruby
notice = Uchujin::Notice.build(exception, ...)
Uchujin.configuration.before_notify_callbacks.each do |cb|
  result = cb.call(notice)
  return if result == false || result == :skip
end
# enqueue notice.to_h
```

### Config API

```ruby
Uchujin.configure do |config|
  config.before_notify do |notice|
    notice.skip! if notice.message =~ /Sidekiq::Quiet/
    notice.context["tenant"] = Current.tenant_id
  end

  config.fingerprint do |exception, notice|
    # e.g. group all Stripe timeouts together
    if exception.message.include?("Stripe")
      Digest::SHA256.hexdigest("stripe:#{exception.class}")
    end # nil → default Fingerprint.generate
  end

  config.user_context do
    u = current_user # only works if block instance_exec'd in controller — prefer request-based
    { id: u&.id, email: u&.email }
  end
end
```

**Auth note:** `user_context` for capture cannot use controller helpers unless we set context in a host `around_action`. Prefer:

```ruby
# host ApplicationController
around_action :uchujin_user_context
def uchujin_user_context
  Uchujin.context(user_id: current_user&.id, user_email: current_user&.email) if user_signed_in?
  yield
end
```

Document this; optional generator insert. Engine can also subscribe to Warden hooks if present.

### CurrentAttributes

```ruby
config.include_current_attributes = true
# merges Current.attributes (stringified, filtered) into notice context
```

### Fingerprint change

```ruby
# Fingerprint.generate(...)
custom = configuration.fingerprint_proc&.call(exception, notice)
custom.presence || default_digest
```

### Filter helpers

```ruby
config.context_filter_parameters = %i[ssn national_id]
# merged into ParameterFilter for context + locals (plan 002)
```

## Implementation steps

1. Introduce `Uchujin::Notice` value object (or keep Hash + helpers).
2. `before_notify` array on Configuration; run in `notify`.
3. Fingerprint proc.
4. Optional CurrentAttributes merge in Context.capture.
5. README + vs-honeybadger mapping table update.
6. Tests for skip, enrich, custom fingerprint.

## Acceptance

- [ ] `before_notify { |n| n.skip! }` drops enqueue
- [ ] Custom fingerprint groups two different messages as one fault
- [ ] CurrentAttributes keys appear on occurrence when enabled
- [ ] Filtered keys never stored

## References

- Honeybadger configuration / notice callbacks  
- Sentry `before_send` / fingerprint rules  
- RED CurrentAttributes integration  
