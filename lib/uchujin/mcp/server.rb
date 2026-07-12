# frozen_string_literal: true

module Uchujin
  module Mcp
    # Minimal MCP JSON-RPC 2.0 server (tools only) over HTTP.
    # Compatible with agents that speak initialize / tools/list / tools/call / ping.
    class Server
      PROTOCOL_VERSION = "2024-11-05"
      SERVER_NAME = "uchujin"
      SERVER_VERSION = Uchujin::VERSION

      TOOLS = {
        "list_faults" => Tools::ListFaults,
        "search_faults" => Tools::SearchFaults,
        "get_fault" => Tools::GetFault,
        "get_occurrence" => Tools::GetOccurrence,
        "list_occurrences" => Tools::ListOccurrences,
        "stats" => Tools::Stats,
        "resolve_fault" => Tools::ResolveFault,
        "ignore_fault" => Tools::IgnoreFault,
        "reopen_fault" => Tools::ReopenFault,
        "assign_fault" => Tools::AssignFault,
        "update_fault" => Tools::UpdateFault,
        "add_comment" => Tools::AddComment,
        "bulk_update_faults" => Tools::BulkUpdateFaults,
        "delete_fault" => Tools::DeleteFault,
        "list_deployments" => Tools::ListDeployments,
        "record_deployment" => Tools::RecordDeployment,
        "list_check_ins" => Tools::ListCheckIns,
        "ping_check_in" => Tools::PingCheckIn,
        "list_uptime" => Tools::ListUptime
      }.freeze

      def handle(body)
        payload = parse_body(body)
        return error_response(nil, -32700, "Parse error") if payload.nil?

        if payload.is_a?(Array)
          return payload.map { |msg| dispatch(msg) }
        end

        dispatch(payload)
      end

      def tools
        TOOLS
      end

      private

      def parse_body(body)
        return nil if body.blank?
        JSON.parse(body)
      rescue JSON::ParserError
        nil
      end

      def dispatch(message)
        return error_response(nil, -32600, "Invalid Request") unless message.is_a?(Hash)

        id = message["id"]
        method = message["method"].to_s
        params = message["params"] || {}

        # Notifications have no id — acknowledge silently
        if id.nil? && method.start_with?("notifications/")
          return nil
        end

        result =
          case method
          when "initialize" then initialize_result(params)
          when "ping" then {}
          when "tools/list" then tools_list_result
          when "tools/call" then tools_call_result(params)
          when "resources/list" then { resources: [] }
          when "prompts/list" then { prompts: [] }
          else
            return error_response(id, -32601, "Method not found: #{method}")
          end

        success_response(id, result)
      rescue => e
        error_response(id, -32603, "Internal error: #{e.class}: #{e.message}")
      end

      def initialize_result(_params)
        {
          protocolVersion: PROTOCOL_VERSION,
          capabilities: {
            tools: { listChanged: false }
          },
          serverInfo: {
            name: SERVER_NAME,
            version: SERVER_VERSION
          },
          instructions: "Uchujin in-process error tracker. Use tools to list/search faults, " \
                        "inspect occurrences, resolve/ignore/reopen, comment, assign, and manage " \
                        "deployments/check-ins/uptime for full triage."
        }
      end

      def tools_list_result
        {
          tools: TOOLS.values.map(&:definition)
        }
      end

      def tools_call_result(params)
        name = params["name"].to_s
        arguments = params["arguments"] || {}
        arguments = {} unless arguments.is_a?(Hash)

        tool = TOOLS[name]
        unless tool
          return tool_error("Unknown tool: #{name}")
        end

        # Symbolize keys for keyword args
        kwargs = arguments.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
        result = tool.call(**kwargs)
        is_error = result.is_a?(Hash) && result.key?(:error)

        {
          content: [
            {
              type: "text",
              text: JSON.pretty_generate(result)
            }
          ],
          isError: is_error,
          structuredContent: result
        }
      rescue ArgumentError => e
        tool_error("Invalid arguments: #{e.message}")
      end

      def tool_error(message)
        {
          content: [ { type: "text", text: JSON.pretty_generate({ error: message }) } ],
          isError: true,
          structuredContent: { error: message }
        }
      end

      def success_response(id, result)
        { jsonrpc: "2.0", id: id, result: result }
      end

      def error_response(id, code, message)
        { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
      end
    end
  end
end
