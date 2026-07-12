# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class IgnoreFault < Tool
        tool_name "ignore_fault"
        description "Mark a fault as ignored (noise / won't fix). Stops reopen notifications until status changes."
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
          fault.ignore!
          { ok: true, fault: Serializers.fault_summary(fault) }
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        end
      end
    end
  end
end
