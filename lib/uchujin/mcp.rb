# frozen_string_literal: true

require "uchujin/mcp/tool"
require "uchujin/mcp/serializers"
require "uchujin/mcp/tools/list_faults"
require "uchujin/mcp/tools/search_faults"
require "uchujin/mcp/tools/get_fault"
require "uchujin/mcp/tools/get_occurrence"
require "uchujin/mcp/tools/list_occurrences"
require "uchujin/mcp/tools/stats"
require "uchujin/mcp/tools/resolve_fault"
require "uchujin/mcp/tools/ignore_fault"
require "uchujin/mcp/tools/reopen_fault"
require "uchujin/mcp/tools/assign_fault"
require "uchujin/mcp/tools/update_fault"
require "uchujin/mcp/tools/add_comment"
require "uchujin/mcp/tools/bulk_update_faults"
require "uchujin/mcp/tools/delete_fault"
require "uchujin/mcp/tools/list_deployments"
require "uchujin/mcp/tools/record_deployment"
require "uchujin/mcp/tools/list_check_ins"
require "uchujin/mcp/tools/ping_check_in"
require "uchujin/mcp/tools/list_uptime"
require "uchujin/mcp/server"

module Uchujin
  module Mcp
    module_function

    def server
      @server ||= Server.new
    end

    def reset_server!
      @server = nil
    end

    def tool_names
      Server::TOOLS.keys
    end
  end
end
