# Plan: MCP server for AI-assisted debugging

**Priority:** P2 (high leverage for Escalante / Claude / Grok workflows)  
**Inspired by:** [Faultline MCP](https://github.com/dlt/faultline) tools  
**Status:** Plan only

## Problem

When debugging production faults, the AI session often lacks live error context. Copy-pasting backtraces is lossy. Faultline exposes MCP tools so assistants can `get_error_group`, list stats, bulk update — while coding.

## Goals

1. Optional **MCP HTTP endpoint** under the engine (e.g. `POST /uchujin/mcp`) or stdio server gem binary.
2. Tools that are **read-mostly** by default; writes gated by same deploy token / admin auth.
3. Tools useful for agent loops: fetch fault, list unresolved, search, mark resolved, add comment.

## Non-goals

- Full Claude plugin marketplace packaging in v1 (document how to register).
- Letting MCP bypass auth.

## Proposed tools

| Tool | Action |
|------|--------|
| `uchujin_list_faults` | query, status, limit |
| `uchujin_get_fault` | id → fault + latest occurrence summary |
| `uchujin_get_occurrence` | full backtrace/context |
| `uchujin_search` | QueryParser string |
| `uchujin_resolve_fault` | write |
| `uchujin_comment` | write |
| `uchujin_stats` | unresolved count, 24h occurrences, spike flag |

## Auth

- Header `Authorization: Bearer <UCHUJIN_DEPLOY_TOKEN>` **or** session cookie for browser MCP bridges.
- Separate `config.mcp_token` if we want deploy token ≠ AI token.
- Disable entirely unless `config.mcp_enabled = true`.

## Transport

**v1 recommendation:** JSON-RPC over HTTP at `/uchujin/api/mcp` (simple for remote agents).  
**v1.1:** `uchujin-mcp` executable using official MCP Ruby/Node bridge if needed.

## Implementation steps

1. Spike minimal JSON-RPC router in engine.
2. Implement read tools + tests.
3. Write tools with auth.
4. Document Claude Desktop / Cursor / Escalante config snippet.
5. Rate limit (reuse storm ideas).

## Acceptance

- [ ] With MCP disabled, route 404/403
- [ ] List + get return real fault data
- [ ] Resolve via MCP updates status
- [ ] Token required in production

## References

- Faultline `lib/faultline/mcp/` and `mcp_controller`
- Model Context Protocol spec  
- Host: Escalante Telegram / Claude already uses MCP pattern (brave-search, mempalace)
