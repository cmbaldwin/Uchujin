# frozen_string_literal: true

module Uchujin
  module Api
    class DeploymentsController < BaseController
      def create
        deployment = Deployment.create!(
          sha: params.require(:sha),
          environment: params[:environment].presence || Rails.env.to_s,
          deployed_at: params[:deployed_at].present? ? Time.zone.parse(params[:deployed_at]) : Time.current,
          repository: params[:repository],
          user: params[:user],
          metadata: params[:metadata].presence || {}
        )
        # Keep revision config in sync for subsequent captures in this process
        Uchujin.configuration.revision = deployment.sha if Uchujin.configuration.revision.blank?
        render json: { id: deployment.id, sha: deployment.sha, environment: deployment.environment }, status: :created
      end
    end
  end
end
