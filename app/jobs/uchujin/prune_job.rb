# frozen_string_literal: true

module Uchujin
  class PruneJob < ApplicationJob
    queue_as { Uchujin.configuration.queue_name }

    def perform
      return unless Uchujin.configuration.pruning_enabled

      retention = Uchujin.configuration.retention_period
      resolved_retention = Uchujin.configuration.resolved_retention_period

      Occurrence.where("occurred_at < ?", retention.ago).delete_all

      Notification.where("created_at < ?", retention.ago).delete_all

      Fault.where(status: %w[resolved ignored])
           .where("COALESCE(resolved_at, updated_at) < ?", resolved_retention.ago)
           .find_each(&:destroy)

      UptimeCheck.where("checked_at < ?", 30.days.ago).delete_all

      # Repair counters drifted by delete_all above (single statement, no N+1).
      Fault.update_all(
        "occurrences_count = (SELECT COUNT(*) FROM uchujin_occurrences " \
        "WHERE uchujin_occurrences.fault_id = uchujin_faults.id)"
      )
    end
  end
end
