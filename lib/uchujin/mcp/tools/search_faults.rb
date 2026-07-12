# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class SearchFaults < Tool
        tool_name "search_faults"
        description "Search faults with Honeybadger-style query syntax: is:unresolved, environment:production, component:job, tag:foo, free text."
        input_schema(
          type: "object",
          properties: {
            query: { type: "string", description: "Search query" },
            limit: { type: "integer", minimum: 1, maximum: 100 }
          },
          required: [ "query" ],
          additionalProperties: false
        )

        def self.call(query:, limit: 25, **_)
          scope = QueryParser.new(query).apply(Fault.all).recent
          faults = scope.limit([[limit.to_i, 1].max, 100].min)
          {
            query: query,
            count: faults.size,
            faults: faults.map { |f| Serializers.fault_summary(f) }
          }
        end
      end
    end
  end
end
