# frozen_string_literal: true

module Uchujin
  class PruneJob < ApplicationJob
    queue_as :uchujin

    def perform
      return unless Uchujin.configuration.pruning_enabled

      retention = Uchujin.configuration.retention_period
      resolved_retention = Uchujin.configuration.resolved_retention_period

      # Drop old occurrences across all faults
      Occurrence.where("occurred_at < ?", retention.ago).delete_all

      # Drop resolved/ignored faults past resolved retention
      Fault.where(status: %w[resolved ignored])
           .where("COALESCE(resolved_at, updated_at) < ?", resolved_retention.ago)
           .find_each(&:destroy)

      # Drop old uptime checks (keep 30 days)
      UptimeCheck.where("checked_at < ?", 30.days.ago).delete_all

      # Recompute occurrence counters
      Fault.find_each do |fault|
        Fault.where(id: fault.id).update_all(occurrences_count: fault.occurrences.count)
      end
    end
  end
end
