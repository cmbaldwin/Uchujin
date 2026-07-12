# frozen_string_literal: true

require "test_helper"

class UchujinMcpServerTest < ActiveSupport::TestCase
  setup do
    Uchujin::Mcp.reset_server!
    @server = Uchujin::Mcp.server
    seed_fault!
  end

  test "initialize returns server info and tools capability" do
    res = @server.handle({ jsonrpc: "2.0", id: 1, method: "initialize", params: {} }.to_json)
    assert_equal "2.0", res[:jsonrpc]
    assert_equal 1, res[:id]
    assert_equal "uchujin", res[:result][:serverInfo][:name]
    assert res[:result][:capabilities][:tools]
  end

  test "tools/list includes triage tools" do
    res = @server.handle({ jsonrpc: "2.0", id: 2, method: "tools/list" }.to_json)
    names = res[:result][:tools].map { |t| t[:name] }
    assert_includes names, "list_faults"
    assert_includes names, "resolve_fault"
    assert_includes names, "add_comment"
    assert_includes names, "bulk_update_faults"
    assert_includes names, "stats"
    assert_operator names.size, :>=, 15
  end

  test "list_faults returns seeded fault" do
    res = call_tool("list_faults", status: "unresolved")
    data = JSON.parse(res[:result][:content][0][:text])
    assert data["count"] >= 1
    assert_equal "RuntimeError", data["faults"].first["class_name"]
  end

  test "search_faults finds by text" do
    res = call_tool("search_faults", query: "boom")
    data = JSON.parse(res[:result][:content][0][:text])
    assert_equal 1, data["count"]
  end

  test "get_fault and get_occurrence" do
    fault = Uchujin::Fault.last
    res = call_tool("get_fault", fault_id: fault.id)
    data = JSON.parse(res[:result][:content][0][:text])
    assert_equal fault.id, data["id"]
    assert data["latest_occurrences"].any?

    occ_id = data["latest_occurrences"].first["id"]
    res2 = call_tool("get_occurrence", occurrence_id: occ_id)
    detail = JSON.parse(res2[:result][:content][0][:text])
    assert_equal occ_id, detail["id"]
    assert detail["backtrace"]
  end

  test "resolve ignore reopen cycle" do
    fault = Uchujin::Fault.last
    call_tool("resolve_fault", fault_id: fault.id)
    assert fault.reload.resolved?

    call_tool("reopen_fault", fault_id: fault.id)
    assert fault.reload.unresolved?

    call_tool("ignore_fault", fault_id: fault.id)
    assert fault.reload.ignored?
  end

  test "add_comment and update tags" do
    fault = Uchujin::Fault.last
    call_tool("add_comment", fault_id: fault.id, body: "Looks like nil cart", author_name: "agent")
    assert_equal 1, fault.comments.count

    call_tool("update_fault", fault_id: fault.id, tags: %w[cart payments])
    assert_equal %w[cart payments], fault.reload.tag_list.sort
  end

  test "bulk_update_faults resolve" do
    fault = Uchujin::Fault.last
    res = call_tool("bulk_update_faults", fault_ids: [ fault.id ], action: "resolve")
    data = JSON.parse(res[:result][:content][0][:text])
    assert data["ok"]
    assert fault.reload.resolved?
  end

  test "stats returns counts" do
    res = call_tool("stats")
    data = JSON.parse(res[:result][:content][0][:text])
    assert data.key?("unresolved")
    assert data.key?("occurrences_24h")
  end

  test "unknown tool returns isError" do
    res = call_tool("nope_tool")
    assert res[:result][:isError]
  end

  test "ping works" do
    res = @server.handle({ jsonrpc: "2.0", id: 9, method: "ping" }.to_json)
    assert_equal({}, res[:result])
  end

  private

  def call_tool(name, **arguments)
    @server.handle({
      jsonrpc: "2.0",
      id: rand(1000),
      method: "tools/call",
      params: { name: name, arguments: arguments }
    }.to_json)
  end

  def seed_fault!
    Uchujin::ProcessNoticeJob.perform_now(
      "class_name" => "RuntimeError",
      "message" => "boom cart empty",
      "backtrace" => [ "#{Rails.root}/app/models/cart.rb:10:in `checkout`" ],
      "component" => "web",
      "environment" => "test",
      "context" => { "order_id" => 1 },
      "breadcrumbs" => [],
      "server_stats" => {},
      "params" => {},
      "request_metadata" => { "path" => "/checkout" },
      "client_info" => {},
      "occurred_at" => Time.current.iso8601
    )
  end
end
