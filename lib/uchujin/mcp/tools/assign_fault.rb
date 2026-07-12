# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class AssignFault < Tool
        tool_name "assign_fault"
        description "Assign a fault to a host-app user id (or clear with null)."
        input_schema(
          type: "object",
          properties: {
            fault_id: { type: "integer" },
            assignee_id: { type: [ "integer", "null" ], description: "Host user id; null to unassign" }
          },
          required: [ "fault_id" ],
          additionalProperties: false
        )

        def self.call(fault_id:, assignee_id: nil, **_)
          fault = Fault.find(fault_id)
          fault.assign!(assignee_id)
          { ok: true, fault: Serializers.fault_summary(fault) }
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        end
      end
    end
  end
end
