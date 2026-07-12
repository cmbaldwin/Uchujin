# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class GetFault < Tool
        tool_name "get_fault"
        description "Get full detail for one fault: metadata, tags, comments, latest occurrences (summaries)."
        input_schema(
          type: "object",
          properties: {
            fault_id: { type: "integer", description: "Fault id" },
            occurrence_limit: { type: "integer", minimum: 1, maximum: 50 }
          },
          required: [ "fault_id" ],
          additionalProperties: false
        )

        def self.call(fault_id:, occurrence_limit: 10, **_)
          fault = Fault.find(fault_id)
          Serializers.fault_detail(fault, occurrence_limit: [[occurrence_limit.to_i, 1].max, 50].min)
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        end
      end
    end
  end
end
