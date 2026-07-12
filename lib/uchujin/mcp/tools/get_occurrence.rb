# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class GetOccurrence < Tool
        tool_name "get_occurrence"
        description "Get a single occurrence with full backtrace, source context, breadcrumbs, request, params, server stats."
        input_schema(
          type: "object",
          properties: {
            occurrence_id: { type: "integer" }
          },
          required: [ "occurrence_id" ],
          additionalProperties: false
        )

        def self.call(occurrence_id:, **_)
          occ = Occurrence.find(occurrence_id)
          Serializers.occurrence_detail(occ)
        rescue ActiveRecord::RecordNotFound
          { error: "occurrence not found", occurrence_id: occurrence_id }
        end
      end
    end
  end
end
