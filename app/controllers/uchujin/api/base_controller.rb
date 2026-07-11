# frozen_string_literal: true

module Uchujin
  module Api
    class BaseController < ActionController::Base
      skip_forgery_protection
      before_action :authenticate_deploy_token!

      private

      def authenticate_deploy_token!
        token = Uchujin.configuration.deploy_token
        if token.blank?
          render json: { error: "deploy token not configured" }, status: :service_unavailable
          return
        end

        provided = request.headers["Authorization"].to_s.sub(/\ABearer\s+/i, "")
        # Prefer Authorization header; query token accepted only outside production
        # to avoid leaking secrets via access logs / referrers.
        if provided.blank? && !Rails.env.production?
          provided = params[:token].to_s
        end

        unless secure_token_match?(provided, token)
          render json: { error: "unauthorized" }, status: :unauthorized
        end
      end

      def secure_token_match?(provided, expected)
        return false if provided.blank? || expected.blank?
        ActiveSupport::SecurityUtils.secure_compare(provided.to_s, expected.to_s)
      rescue ArgumentError
        false
      end
    end
  end
end
