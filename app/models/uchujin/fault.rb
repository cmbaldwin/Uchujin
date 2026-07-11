# frozen_string_literal: true

module Uchujin
  class Fault < ApplicationRecord
    self.table_name = "uchujin_faults"

    STATUSES = %w[unresolved resolved ignored].freeze

    has_many :occurrences, class_name: "Uchujin::Occurrence", dependent: :destroy, inverse_of: :fault
    has_many :comments, class_name: "Uchujin::Comment", dependent: :destroy, inverse_of: :fault
    has_many :notifications, class_name: "Uchujin::Notification", dependent: :destroy, inverse_of: :fault

    validates :fingerprint, presence: true, uniqueness: true
    validates :class_name, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :unresolved, -> { where(status: "unresolved") }
    scope :resolved,   -> { where(status: "resolved") }
    scope :ignored,    -> { where(status: "ignored") }
    scope :recent,     -> { order(last_seen_at: :desc) }

    def resolved?
      status == "resolved"
    end

    def ignored?
      status == "ignored"
    end

    def unresolved?
      status == "unresolved"
    end

    def resolve!(user_id: nil)
      update!(status: "resolved", resolved_at: Time.current, assignee_id: user_id || assignee_id)
    end

    def ignore!
      update!(status: "ignored")
    end

    def reopen!
      update!(status: "unresolved", resolved_at: nil)
    end

    def assign!(user_id)
      update!(assignee_id: user_id)
    end

    def windowed_count(since: 24.hours.ago)
      occurrences.where("occurred_at >= ?", since).count
    end

    def tag_list
      Array(tags)
    end

    def tag_list=(value)
      self.tags = Array(value).map(&:to_s).map(&:strip).reject(&:blank?).uniq
    end
  end
end
