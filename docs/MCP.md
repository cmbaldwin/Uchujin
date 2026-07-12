# Uchujin MCP — AI agent fault triage

Uchujin exposes a **JSON-RPC 2.0 MCP tools** endpoint so any agent (Claude, Cursor, Grok, custom bots) can fully triage production errors without opening the browser UI.

## Enable

```ruby
# config/initializers/uchujin.rb
Uchujin.configure do |config|
  config.mcp_enabled = true
  config.mcp_token = ENV["UCHUJIN_MCP_TOKEN"] # recommended dedicated secret
  # If mcp_token is blank, deploy_token is used instead.
end
```

Or env: `UCHUJIN_MCP_ENABLED=true` and `UCHUJIN_MCP_TOKEN=...`.

**Endpoint:** `POST /uchujin/api/mcp`  
**Auth:** `Authorization: Bearer <token>` (or `X-Uchujin-Token`)

When `mcp_enabled` is false, the route responds **404**.

## Protocol

Supported methods:

| Method | Purpose |
|--------|---------|
| `initialize` | Handshake + server info |
| `ping` | Liveness |
| `tools/list` | All tool definitions + JSON Schema |
| `tools/call` | Invoke a tool |

Example:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "search_faults",
    "arguments": { "query": "is:unresolved environment:production", "limit": 10 }
  }
}
```

Tool results return MCP-style `content` (pretty JSON text) plus `structuredContent` for clients that prefer objects. `isError: true` when the tool payload includes an `error` key.

## Tools (full triage)

### Read

| Tool | What it does |
|------|----------------|
| `stats` | Unresolved/resolved/ignored counts, 1h/24h volume, top faults, overdue check-ins, recent deploys |
| `list_faults` | Filter by status / environment / component |
| `search_faults` | Honeybadger-style query (`is:unresolved`, `tag:x`, free text) |
| `get_fault` | Full fault + comments + latest occurrence summaries |
| `list_occurrences` | Occurrence list for a fault |
| `get_occurrence` | Full backtrace, source context, breadcrumbs, request, params, server stats |
| `list_deployments` | Recent deploy markers |
| `list_check_ins` | Heartbeats + overdue flags |
| `list_uptime` | Latest probe status per URL + history |

### Write (triage)

| Tool | What it does |
|------|----------------|
| `resolve_fault` | Mark resolved (optional assignee) |
| `ignore_fault` | Mark ignored (noise / won't fix) |
| `reopen_fault` | Back to unresolved |
| `assign_fault` | Set/clear `assignee_id` |
| `update_fault` | Replace tags and/or assignee |
| `add_comment` | Investigation notes (author defaults to `mcp-agent`) |
| `bulk_update_faults` | resolve / ignore / reopen many ids |
| `delete_fault` | Permanent delete (`confirm: true` required) |
| `record_deployment` | Create deploy marker |
| `ping_check_in` | Heartbeat ping (creates check-in if needed) |

## Suggested agent workflow

1. `stats` — is the app on fire?
2. `search_faults` with `is:unresolved` — queue
3. `get_fault` + `get_occurrence` — root-cause context
4. `add_comment` — note hypothesis / PR link
5. `resolve_fault` or `ignore_fault` or `assign_fault`
6. Optional: `bulk_update_faults` after a fix ships

## Security

- Keep MCP **off** unless you need agents.
- Prefer a **dedicated** `mcp_token` (not the same as a widely shared deploy token if possible).
- Never expose `/uchujin/api/mcp` without TLS.
- Token in query string is only accepted outside production.
- Agents can resolve/delete faults — treat the token like production credentials.

## Client config sketches

### curl

```bash
export UCHUJIN_MCP_TOKEN=...
export UCHUJIN_MCP_URL=https://akotacos.moab.jp/uchujin/api/mcp

curl -sS -X POST "$UCHUJIN_MCP_URL" \
  -H "Authorization: Bearer $UCHUJIN_MCP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"stats","arguments":{}}}'
```

### Generic HTTP MCP bridge

Point your agent’s HTTP MCP transport at `POST /uchujin/api/mcp` with the Bearer header. No extra gem is required on the host — the server is pure JSON-RPC inside the engine.

## Implementation notes

- No dependency on the `mcp` Ruby gem (zero extra deps).
- Tools live in `lib/uchujin/mcp/tools/*`.
- Router: `Uchujin::Mcp::Server`.
- Controller: `Uchujin::Api::McpController`.
