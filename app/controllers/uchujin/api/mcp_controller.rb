# frozen_string_literal: true

module Uchujin
  module Api
    # MCP JSON-RPC endpoint for AI agents.
    #
    #   POST /uchujin/api/mcp
    #   Authorization: Bearer <mcp_token or deploy_token>
    #   Content-Type: application/json
    #
    # Speaks initialize, tools/list, tools/call, ping.
    class McpController < ActionController::Base
      skip_forgery_protection
      before_action :ensure_mcp_enabled!
      before_action :authenticate_mcp_token!

      def handle
        response = Uchujin::Mcp.server.handle(request.raw_post)

        if response.nil?
          head :accepted
        else
          render json: response, status: :ok
        end
      end

      private

      def ensure_mcp_enabled!
        return if Uchujin.configuration.mcp_enabled

        render json: { error: "MCP is disabled. Set config.mcp_enabled = true" }, status: :not_found
      end

      def authenticate_mcp_token!
        token = Uchujin.configuration.effective_mcp_token
        if token.blank?
          render json: { error: "MCP token not configured (mcp_token or deploy_token)" }, status: :service_unavailable
          return
        end

        provided = bearer_token
        if provided.blank? && !Rails.env.production?
          provided = params[:token].to_s
        end

        unless secure_match?(provided, token)
          render json: { error: "unauthorized" }, status: :unauthorized
        end
      end

      def bearer_token
        header = request.headers["Authorization"].to_s
        return header.delete_prefix("Bearer ").strip if header.start_with?("Bearer ")
        # Also accept X-Uchujin-Token
        request.headers["X-Uchujin-Token"].presence
      end

      def secure_match?(provided, expected)
        return false if provided.blank? || expected.blank?
        ActiveSupport::SecurityUtils.secure_compare(provided.to_s, expected.to_s)
      rescue ArgumentError
        false
      end
    end
  end
end
