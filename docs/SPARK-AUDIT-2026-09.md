# Spark 1.3 audit — Uchujin — 2026-09-03

Spark timed out after 90 minutes while debugging a broken `create_or_find_by!` on check-in ping. Orchestrator kept the four working fixes, restored `find_or_initialize_by` for ping, and kept Spark's cadence sanitization.

## The 10 (from the session)

1. Check-in ping race / uniqueness (High / S) — Spark tried `create_or_find_by!`; uniqueness validation raises `RecordInvalid` on the second ping. Reverted that approach.
2. Garbage `expected_every_seconds` on ping (Medium / S).
3. Deploy hook 500s on unparseable `deployed_at` (Medium / S).
4. MCP Bearer parse is case-sensitive vs deploy API (Low / S).
5. `PruneJob` N+1 `occurrences_count` repair (Medium / S).
6. Job breadcrumbs/context leak across reused worker threads (Medium / S).
7. Broader MCP tool coverage (Medium / M) — skipped, too big.
8. Dashboard charts / mute-snooze plans already in open PRs — skipped.
9. Production deploy/token rotation — needs owner.
10. Docs-only Ox audit leftovers — skipped.

## The 5 shipped

- **Ping cadence:** ignore non-numeric `expected_every_seconds`; record a positive cadence once. Keep `find_or_initialize_by`.
- **Deploy `deployed_at`:** garbage timestamps fall back to `Time.current` (no 500).
- **MCP auth:** case-insensitive `Bearer` scheme; still accepts `X-Uchujin-Token`.
- **PruneJob:** single SQL `occurrences_count` repair instead of per-fault N+1.
- **JobErrorHandling:** clear breadcrumbs + context at the start of each job.

## Skipped

- `create_or_find_by!` ping (broken; uniqueness validation).
- Open Uchujin plan PRs (#8–#14).
- Anything needing production credentials.
