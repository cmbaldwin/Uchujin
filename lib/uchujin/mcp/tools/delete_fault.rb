# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class DeleteFault < Tool
        tool_name "delete_fault"
        description "Permanently delete a fault and all its occurrences/comments. Destructive — prefer ignore for noise."
        input_schema(
          type: "object",
          properties: {
            fault_id: { type: "integer" },
            confirm: { type: "boolean", description: "Must be true to proceed" }
          },
          required: [ "fault_id", "confirm" ],
          additionalProperties: false
        )
        annotations(destructiveHint: true)

        def self.call(fault_id:, confirm:, **_)
          return { error: "confirm must be true" } unless confirm == true

          fault = Fault.find(fault_id)
          summary = Serializers.fault_summary(fault)
          fault.destroy!
          { ok: true, deleted: summary }
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        end
      end
    end
  end
end
