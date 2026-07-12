# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class ResolveFault < Tool
        tool_name "resolve_fault"
        description "Mark a fault as resolved (workflow: done triaging / fixed)."
        input_schema(
          type: "object",
          properties: {
            fault_id: { type: "integer" },
            assignee_id: { type: "integer", description: "Optional assignee user id" }
          },
          required: [ "fault_id" ],
          additionalProperties: false
        )
        annotations(destructiveHint: false, readOnlyHint: false)

        def self.call(fault_id:, assignee_id: nil, **_)
          fault = Fault.find(fault_id)
          fault.resolve!(user_id: assignee_id)
          { ok: true, fault: Serializers.fault_summary(fault) }
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        end
      end
    end
  end
end
