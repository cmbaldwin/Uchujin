# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class UpdateFault < Tool
        tool_name "update_fault"
        description "Update fault tags and/or assignee. Tags replace the full list when provided."
        input_schema(
          type: "object",
          properties: {
            fault_id: { type: "integer" },
            tags: {
              type: "array",
              items: { type: "string" },
              description: "Full tag list (replaces existing)"
            },
            assignee_id: { type: [ "integer", "null" ] }
          },
          required: [ "fault_id" ],
          additionalProperties: false
        )

        def self.call(fault_id:, tags: nil, assignee_id: :__unset__, **_)
          fault = Fault.find(fault_id)
          fault.tag_list = tags if !tags.nil?
          fault.assignee_id = assignee_id unless assignee_id == :__unset__
          fault.save!
          { ok: true, fault: Serializers.fault_summary(fault) }
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        rescue ActiveRecord::RecordInvalid => e
          { error: e.message, fault_id: fault_id }
        end
      end
    end
  end
end
