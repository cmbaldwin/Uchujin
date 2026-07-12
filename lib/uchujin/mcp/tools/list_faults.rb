# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class ListFaults < Tool
        tool_name "list_faults"
        description "List Uchujin faults (error groups), newest first. Filter by status/environment/component."
        input_schema(
          type: "object",
          properties: {
            status: { type: "string", enum: %w[unresolved resolved ignored], description: "Filter by status" },
            environment: { type: "string" },
            component: { type: "string" },
            limit: { type: "integer", minimum: 1, maximum: 100, description: "Max results (default 25)" }
          },
          additionalProperties: false
        )

        def self.call(status: nil, environment: nil, component: nil, limit: 25, **_)
          scope = Fault.recent
          scope = scope.where(status: status) if status.present?
          scope = scope.where(environment: environment) if environment.present?
          scope = scope.where(component: component) if component.present?
          faults = scope.limit([[limit.to_i, 1].max, 100].min)
          {
            count: faults.size,
            faults: faults.map { |f| Serializers.fault_summary(f) }
          }
        end
      end
    end
  end
end
