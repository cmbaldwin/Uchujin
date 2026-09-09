# frozen_string_literal: true

module Uchujin
  module Api
    class DeploymentsController < BaseController
      def create
        deployment = Deployment.create!(
          sha: params.require(:sha),
          environment: params[:environment].presence || Rails.env.to_s,
          deployed_at: parse_deployed_at(params[:deployed_at]),
          repository: params[:repository],
          user: params[:user],
          metadata: params[:metadata].presence || {}
        )
        # Keep revision config in sync for subsequent captures in this process
        Uchujin.configuration.revision = deployment.sha if Uchujin.configuration.revision.blank?
        render json: { id: deployment.id, sha: deployment.sha, environment: deployment.environment }, status: :created
      end

      private

      # Never 500 a deploy hook on a bad timestamp: garbage falls back to now.
      def parse_deployed_at(value)
        return Time.current if value.blank?
        Time.zone.parse(value.to_s) || Time.current
      rescue ArgumentError
        Time.current
      end
    end
  end
end
