# frozen_string_literal: true

module Uchujin
  class CheckIn < ApplicationRecord
    self.table_name = "uchujin_check_ins"

    validates :name, presence: true, uniqueness: true

    def overdue?
      return false if expected_every_seconds.blank? || last_seen_at.blank?
      last_seen_at < expected_every_seconds.seconds.ago
    end

    def ping!
      update!(last_seen_at: Time.current, ping_count: ping_count.to_i + 1)
    end
  end
end
