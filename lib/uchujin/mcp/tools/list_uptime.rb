# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class ListUptime < Tool
        tool_name "list_uptime"
        description "Latest uptime probe status per URL, plus recent history."
        input_schema(
          type: "object",
          properties: {
            history_limit: { type: "integer", minimum: 1, maximum: 100 }
          },
          additionalProperties: false
        )

        def self.call(history_limit: 20, **_)
          history = UptimeCheck.order(checked_at: :desc).limit([[history_limit.to_i, 1].max, 100].min)
          latest = UptimeCheck.order(checked_at: :desc).limit(200).group_by(&:url).transform_values(&:first)
          {
            latest: latest.map { |_url, check| Serializers.uptime_check(check) },
            history: history.map { |c| Serializers.uptime_check(c) }
          }
        end
      end
    end
  end
end
