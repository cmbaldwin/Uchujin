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

      Fault.find_each do |fault|
        Fault.where(id: fault.id).update_all(occurrences_count: fault.occurrences.count)
      end
    end
  end
end
