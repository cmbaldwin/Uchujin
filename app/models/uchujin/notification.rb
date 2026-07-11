# frozen_string_literal: true

module Uchujin
  class Notification < ApplicationRecord
    self.table_name = "uchujin_notifications"

    CHANNELS = %w[email slack webhook].freeze

    belongs_to :fault, class_name: "Uchujin::Fault", inverse_of: :notifications, optional: true

    validates :channel, inclusion: { in: CHANNELS }
  end
end
