# Plan: GitHub issues + operator workflow (mute, snooze, batch)

**Priority:** P2  
**Inspired by:** Faultline GitHub integration, rails_error_dashboard workflow (mute/snooze/assign/batch), Honeybadger issue links  
**Status:** Plan only

## Problem

Faults are tracked in-app but real work often lives in GitHub Issues. Also:

- **Ignore** is permanent-ish; sometimes you want **snooze 7 days** (noise during known outage).
- **Mute** = keep tracking, stop emails (RED distinction).
- No batch resolve from index.

## Goals

1. **Create GitHub issue** from fault show (title, body with link, class, message, top frames, occurrence count).
2. Store `github_issue_url` / `github_issue_number` on fault; button becomes “View issue”.
3. **Snooze until** timestamp — auto-unresolved when snooze expires and new occurrence arrives (or cron).
4. **Mute notifications** flag separate from ignore (still visible in UI).
5. **Batch actions** on index: resolve / ignore / mute selected.

## Non-goals

- Full two-way GitHub sync / project boards.
- Jira/Linear (design notifier interface so they can plug later).
- Re-adding Slack (use issue assignment instead).

## Design sketch

### Schema additions (`uchujin_faults`)

```ruby
t.string   :github_issue_url
t.integer  :github_issue_number
t.datetime :snoozed_until
t.boolean  :muted, default: false, null: false
t.integer  :priority  # optional 0-3
```

### GitHub client

```ruby
config.github_repo = "cmbaldwin/akotacos.moab.jp"
config.github_token = ENV["UCHUJIN_GITHUB_TOKEN"]  # fine-grained: issues write
config.github_labels = %w[bug uchujin]
```

Use `Octokit` optional dependency **or** raw Net::HTTP to avoid hard dep:

```ruby
# prefer Net::HTTP POST /repos/:owner/:repo/issues
```

### Notifier interaction

```ruby
def deliver
  return if @fault.muted?
  return if @fault.snoozed_until&.future?
  ...
end
```

### UI

- Fault show: “Open GitHub issue” | “Mute emails” | “Snooze 24h / 7d”
- Index: checkboxes + bulk bar
- Badge: muted / snoozed

### Auto-reopen

Already reopen on occurrence if resolved. Extend: if snoozed and `Time.current > snoozed_until`, clear snooze on new occurrence and notify once.

## Implementation steps

1. Migration + model methods (`mute!`, `snooze!(duration)`, `create_github_issue!`).
2. `Uchujin::Github::IssueCreator` service.
3. Controller member/collection actions.
4. Notifier guards.
5. Views + tests (WebMock GitHub API).
6. Docs: token scopes, security.

## Acceptance

- [ ] Issue created with useful body and stored URL
- [ ] Muted fault does not email
- [ ] Snoozed fault silences until expiry
- [ ] Batch resolve 3 faults in one request
- [ ] Without github_token, button shows config hint

## References

- Faultline `github_issue_creator.rb`  
- RED create_issue_job / mute / snooze  
- Honeybadger issue tracker integrations  
