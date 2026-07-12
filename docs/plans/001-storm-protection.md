# Plan: Storm protection (adaptive sampling + circuit breaker)

**Priority:** P0 — must-have for any in-process tracker  
**Inspired by:** [rails_error_dashboard](https://github.com/AnjanJ/rails_error_dashboard) storm protection  
**Status:** Plan only — not implemented

## Problem

A bad deploy that throws on every request can enqueue thousands of `ProcessNoticeJob`s and write thousands of `uchujin_occurrences` rows — amplifying the outage with our own DB/queue load. SaaS products absorb this in the cloud; we share the host’s Postgres and SolidQueue.

## Goals

1. **Degrade ourselves first** under flood (never make a bad deploy worse).
2. Keep **honest counts** (exact when possible; never invent numbers).
3. Always keep at least **one full-context exemplar** per fingerprint per time window.
4. **Fail open** — if storm code errors, capture fully (protection must not lose errors).
5. **Default on**, configurable thresholds, disable flag.

## Non-goals

- Full APM.
- Cross-process distributed rate limits (per-process is enough for Puma/SolidQueue workers; document multi-process math).

## Design sketch

### Layers (checked in order inside `Uchujin.notify` / before enqueue)

```
1. Existing ignore / reentrancy / same-object dedup
2. Per-fingerprint minute budget
   - first N: full notice
   - next M: count-only (no breadcrumbs/params/source context)
   - beyond: sample (e.g. 1/10) still count all via in-memory counter
3. Global process circuit breaker
   - if errors/sec > threshold for sustained window → count-only mode
   - flush counters to Fault.occurrences_count every ~30s via StormFlushJob
4. Notify path
   - rate limit already exists
   - during storm: single “storm active” email, not per-fault spam
```

### Data

New optional table `uchujin_storm_events`:

| column | purpose |
|--------|---------|
| started_at / ended_at | episode window |
| peak_rate | max errors/sec observed |
| shed_full_context | count of context-shed captures |
| shed_sampled | count of dropped samples |
| notes | json |

Or start without a table: in-memory + dashboard banner only; persist later.

### Config

```ruby
config.storm_protection = true           # default true
config.storm_fingerprint_full_per_minute = 25
config.storm_fingerprint_sample_after = 100
config.storm_open_threshold_per_second = 50  # per process
config.storm_calm_after = 60.seconds
```

### UI

- Dashboard banner when any process is in open breaker (via cache key `uchujin:storm:open`).
- Fault show: badge “sampled during storm” on thin occurrences.
- Optional Storm History page (P0.1).

### Tests

- Unit: counter increments, sampling determinism, fail-open on internal error.
- Integration: flood 200 identical exceptions → bounded occurrence rows, occurrences_count ≈ 200 after flush.
- Multi-thread safety (Concurrent::AtomicFixnum or Redis if present — prefer pure Ruby + Mutex first).

## Implementation steps

1. `Uchujin::StormGuard` module (hot path < few µs).
2. Wire into `Uchujin.notify` before building heavy notice hash.
3. Count-only notice shape in `ProcessNoticeJob` (skip source context).
4. `StormFlushJob` recurring (host `recurring.yml` doc).
5. Dashboard banner + config docs.
6. Feature flag off path tested.

## Acceptance

- [ ] Flood of 1k identical errors creates ≪ 1k full occurrence rows
- [ ] Fault counter still reflects true total after flush
- [ ] Protection internal failure does not drop captures
- [ ] `config.storm_protection = false` restores current behavior
- [ ] Docs + CHANGELOG

## References

- RED README “Storm Protection — Circuit Breaker + Adaptive Sampling”
- Uchujin `ProcessNoticeJob`, `Notifier#rate_limited?`
