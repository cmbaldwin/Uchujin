# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class ReopenFault < Tool
        tool_name "reopen_fault"
        description "Reopen a resolved or ignored fault as unresolved."
        input_schema(
          type: "object",
          properties: {
            fault_id: { type: "integer" }
          },
          required: [ "fault_id" ],
          additionalProperties: false
        )

        def self.call(fault_id:, **_)
          fault = Fault.find(fault_id)
          fault.reopen!
          { ok: true, fault: Serializers.fault_summary(fault) }
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        end
      end
    end
  end
end
