# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class Stats < Tool
        tool_name "stats"
        description "Dashboard stats: unresolved/resolved/ignored counts, 24h occurrences, top noisy faults, overdue check-ins."
        input_schema(
          type: "object",
          properties: {},
          additionalProperties: false
        )

        def self.call(**_)
          top = Fault.unresolved.recent.limit(5)
          {
            app_name: Uchujin.configuration.app_name,
            environment: Rails.env,
            unresolved: Fault.unresolved.count,
            resolved: Fault.resolved.count,
            ignored: Fault.ignored.count,
            occurrences_24h: Occurrence.where("occurred_at >= ?", 24.hours.ago).count,
            occurrences_1h: Occurrence.where("occurred_at >= ?", 1.hour.ago).count,
            top_unresolved: top.map { |f| Serializers.fault_summary(f) },
            overdue_check_ins: CheckIn.all.select(&:overdue?).map { |c| Serializers.check_in(c) },
            recent_deployments: Deployment.newest.limit(5).map { |d| Serializers.deployment(d) }
          }
        end
      end
    end
  end
end
