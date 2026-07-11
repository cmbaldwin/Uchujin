# frozen_string_literal: true

module Uchujin
  class UptimeCheck < ApplicationRecord
    self.table_name = "uchujin_uptime_checks"

    STATUSES = %w[up down unknown].freeze

    validates :url, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :newest, -> { order(checked_at: :desc) }
  end
end
