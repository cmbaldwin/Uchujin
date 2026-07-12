# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class ListOccurrences < Tool
        tool_name "list_occurrences"
        description "List recent occurrences for a fault (newest first)."
        input_schema(
          type: "object",
          properties: {
            fault_id: { type: "integer" },
            limit: { type: "integer", minimum: 1, maximum: 100 }
          },
          required: [ "fault_id" ],
          additionalProperties: false
        )

        def self.call(fault_id:, limit: 20, **_)
          fault = Fault.find(fault_id)
          occs = fault.occurrences.newest.limit([[limit.to_i, 1].max, 100].min)
          {
            fault_id: fault.id,
            count: occs.size,
            occurrences: occs.map { |o| Serializers.occurrence_summary(o) }
          }
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        end
      end
    end
  end
end
