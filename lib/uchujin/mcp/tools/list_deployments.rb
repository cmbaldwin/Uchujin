# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class ListDeployments < Tool
        tool_name "list_deployments"
        description "List recent deploys recorded in Uchujin."
        input_schema(
          type: "object",
          properties: {
            environment: { type: "string" },
            limit: { type: "integer", minimum: 1, maximum: 100 }
          },
          additionalProperties: false
        )

        def self.call(environment: nil, limit: 20, **_)
          scope = Deployment.newest
          scope = scope.where(environment: environment) if environment.present?
          rows = scope.limit([[limit.to_i, 1].max, 100].min)
          { count: rows.size, deployments: rows.map { |d| Serializers.deployment(d) } }
        end
      end
    end
  end
end
