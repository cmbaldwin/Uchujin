# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class ListCheckIns < Tool
        tool_name "list_check_ins"
        description "List cron/heartbeat check-ins and whether any are overdue."
        input_schema(
          type: "object",
          properties: {},
          additionalProperties: false
        )

        def self.call(**_)
          rows = CheckIn.order(:name)
          {
            count: rows.size,
            overdue_count: rows.count(&:overdue?),
            check_ins: rows.map { |c| Serializers.check_in(c) }
          }
        end
      end
    end
  end
end
