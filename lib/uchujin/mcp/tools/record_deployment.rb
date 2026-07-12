# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class RecordDeployment < Tool
        tool_name "record_deployment"
        description "Record a deployment marker (sha + environment) for correlation with new faults."
        input_schema(
          type: "object",
          properties: {
            sha: { type: "string" },
            environment: { type: "string" },
            user: { type: "string" },
            repository: { type: "string" },
            deployed_at: { type: "string", description: "ISO8601; default now" }
          },
          required: [ "sha" ],
          additionalProperties: false
        )

        def self.call(sha:, environment: nil, user: nil, repository: nil, deployed_at: nil, **_)
          at = deployed_at.present? ? Time.zone.parse(deployed_at.to_s) : Time.current
          deployment = Deployment.create!(
            sha: sha.to_s,
            environment: environment.presence || Rails.env.to_s,
            deployed_at: at,
            user: user,
            repository: repository
          )
          { ok: true, deployment: Serializers.deployment(deployment) }
        rescue => e
          { error: e.message }
        end
      end
    end
  end
end
