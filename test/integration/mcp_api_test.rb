# frozen_string_literal: true

require "test_helper"

class McpApiTest < ActionDispatch::IntegrationTest
  include Uchujin::Engine.routes.url_helpers

  setup do
    @routes = Uchujin::Engine.routes
    Uchujin.reset_configuration!
    Uchujin.configure do |config|
      config.app_name = "Uchujin Test"
      config.environments = %w[test]
      config.deploy_token = "test-deploy-token"
      config.mcp_enabled = true
      config.mcp_token = "mcp-secret"
    end
  end

  test "mcp disabled returns 404" do
    Uchujin.configuration.mcp_enabled = false
    post api_mcp_path,
         params: { jsonrpc: "2.0", id: 1, method: "ping" },
         headers: auth_headers("mcp-secret"),
         as: :json
    assert_response :not_found
  end

  test "missing token unauthorized" do
    post api_mcp_path,
         params: { jsonrpc: "2.0", id: 1, method: "ping" },
         as: :json
    assert_response :unauthorized
  end

  test "tools list and resolve via HTTP" do
    Uchujin::ProcessNoticeJob.perform_now(
      "class_name" => "NoMethodError",
      "message" => "undefined method x",
      "backtrace" => [ "#{Rails.root}/app/foo.rb:1" ],
      "component" => "web",
      "environment" => "test",
      "occurred_at" => Time.current.iso8601
    )
    fault = Uchujin::Fault.last

    post api_mcp_path,
         params: { jsonrpc: "2.0", id: 1, method: "tools/list" },
         headers: auth_headers("mcp-secret"),
         as: :json
    assert_response :success
    body = JSON.parse(response.body)
    names = body.dig("result", "tools").map { |t| t["name"] }
    assert_includes names, "resolve_fault"

    post api_mcp_path,
         params: {
           jsonrpc: "2.0",
           id: 2,
           method: "tools/call",
           params: { name: "resolve_fault", arguments: { fault_id: fault.id } }
         },
         headers: auth_headers("mcp-secret"),
         as: :json
    assert_response :success
    assert fault.reload.resolved?
  end

  test "falls back to deploy_token when mcp_token blank" do
    Uchujin.configuration.mcp_token = nil
    post api_mcp_path,
         params: { jsonrpc: "2.0", id: 1, method: "ping" },
         headers: auth_headers("test-deploy-token"),
         as: :json
    assert_response :success
  end

  private

  def auth_headers(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
