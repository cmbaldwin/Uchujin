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
        provided = params[:token].to_s if provided.blank?
        unless ActiveSupport::SecurityUtils.secure_compare(provided.to_s, token.to_s)
          render json: { error: "unauthorized" }, status: :unauthorized
        end
      end
    end
  end
end
