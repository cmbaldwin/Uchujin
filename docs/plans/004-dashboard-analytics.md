# Plan: Dashboard analytics — trends, spikes, charts

**Priority:** P2  
**Inspired by:** Faultline charts, rails_error_dashboard analytics, Honeybadger project overview  
**Status:** Plan only

## Problem

Dashboard today shows raw counts and a recent-fault list. Operators cannot see:

- Is error volume rising after last deploy?  
- Which hour spiked?  
- Unresolved trend over 7/30 days  

## Goals

1. **Occurrence histogram** (last 24h hourly, last 7d daily) on dashboard.
2. **Spike badge** when last hour ≫ baseline (simple z-score or 3× median).
3. **Per-fault sparkline** or 24h count (already have `windowed_count` — surface it).
4. **Deploy markers on chart** (vertical lines from `uchujin_deployments`).
5. Zero new JS framework — lightweight Chart.js/vanilla or pure CSS bars (keep gem simple).

## Non-goals

- Real-time websocket dashboards.
- Full APM response-time charts (Faultline experimental APM — out of scope).

## Design sketch

### Queries (Postgres-friendly)

```sql
-- hourly last 24h
SELECT date_trunc('hour', occurred_at) AS bucket, COUNT(*)
FROM uchujin_occurrences
WHERE occurred_at > NOW() - INTERVAL '24 hours'
GROUP BY 1 ORDER BY 1;
```

SQLite dummy: `strftime('%Y-%m-%d %H:00', occurred_at)`.

Abstract in `Uchujin::Analytics.occurrence_buckets(range:, step:)`.

### Spike detection

```ruby
baseline = buckets[0..-3].map(&:count).median
spike = buckets.last.count > [baseline * 3, baseline + 10].max
```

### UI

- Dashboard top: SVG/CSS bar chart (no npm) — array of heights.
- Optional Turbo frame refresh every 60s.
- Fault index: column “24h” already partly there via count — add trend arrow.

### Caching

Cache buckets 1 minute in `Rails.cache` to avoid dashboard hammering DB.

## Implementation steps

1. `Uchujin::Analytics` query module + adapter for sqlite/pg.
2. Dashboard controller assigns `@hourly`, `@daily`, `@spike`.
3. Partial `_chart.html.erb` pure CSS flex bars.
4. Overlay deploy timestamps as labels.
5. Tests with frozen time + inserted occurrences.

## Acceptance

- [ ] Empty state chart OK
- [ ] 24h chart matches known fixture counts
- [ ] Spike flag true under synthetic flood
- [ ] Deploy markers appear when deployments exist

## References

- Faultline `charts.js` / performance index (we take charts only, not APM)
- RED dashboard overview screenshots  
