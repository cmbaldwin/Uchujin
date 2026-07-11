# frozen_string_literal: true

module Uchujin
  class DashboardController < ApplicationController
    def show
      @unresolved_count = Fault.unresolved.count
      @resolved_count = Fault.resolved.count
      @ignored_count = Fault.ignored.count
      @occurrences_24h = Occurrence.where("occurred_at >= ?", 24.hours.ago).count
      @recent_faults = Fault.unresolved.recent.limit(10)
      @recent_deployments = Deployment.newest.limit(5)
      @latest_uptime = latest_uptime_by_url
      @overdue_check_ins = CheckIn.all.select(&:overdue?)
    end

    private

    def latest_uptime_by_url
      UptimeCheck.order(checked_at: :desc).limit(50).group_by(&:url).transform_values(&:first)
    end
  end
end
