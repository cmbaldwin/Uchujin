# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class BulkUpdateFaults < Tool
        tool_name "bulk_update_faults"
        description "Bulk resolve, ignore, or reopen many faults by id."
        input_schema(
          type: "object",
          properties: {
            fault_ids: {
              type: "array",
              items: { type: "integer" },
              minItems: 1,
              maxItems: 100
            },
            action: { type: "string", enum: %w[resolve ignore reopen] }
          },
          required: [ "fault_ids", "action" ],
          additionalProperties: false
        )

        def self.call(fault_ids:, action:, **_)
          ids = Array(fault_ids).map(&:to_i).uniq.first(100)
          updated = []
          missing = []

          ids.each do |id|
            fault = Fault.find_by(id: id)
            if fault.nil?
              missing << id
              next
            end
            case action.to_s
            when "resolve" then fault.resolve!
            when "ignore" then fault.ignore!
            when "reopen" then fault.reopen!
            else
              return { error: "unknown action", action: action }
            end
            updated << Serializers.fault_summary(fault)
          end

          { ok: true, action: action, updated_count: updated.size, missing_ids: missing, faults: updated }
        end
      end
    end
  end
end
