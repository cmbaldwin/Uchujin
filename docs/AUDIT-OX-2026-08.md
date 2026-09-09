Date: 2026-08-21
Model: Ox Alpha (`stealth/ox-alpha`) draft + Grok 4.5 verification
Scope: design, security, function/correctness, efficiency
Method: Ox saw a truncated tree snapshot and often dumped planning instead of a report. Findings below are **only those Grok confirmed against the working tree**. Invented files and unverified “add tests” notes were dropped.

# Audit: Uchujin

## Snapshot
Rails engine: in-process error tracker (Sentry-shaped) with dashboard, mail, deploy pings, MCP. Mount at `/uchujin`.

## Design
- Host supplies `config.authenticate` in an initializer. `Uchujin::ApplicationController#run_host_authentication` **fail-closes in production** if that block is missing (403). Ox “no auth” is **wrong** at the gem layer. AKO TACOS already gates on admin (`akotacos.moab.jp` initializer).

## Security
- MCP (`POST /uchujin/api/mcp`) uses `UCHUJIN_MCP_TOKEN` falling back to deploy token. Keep those distinct in production.
- Breadcrumb subscriber records truncated SQL — expected, but don’t log bind values (current payload is SQL string only).

## Suggested follow-ups
1. Document threat model for MCP vs dashboard auth in `README` — Effort S
2. Refuse MCP enablement when token is blank even if `UCHUJIN_MCP_ENABLED=true` (verify current behavior) — Effort S
