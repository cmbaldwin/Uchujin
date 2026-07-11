# frozen_string_literal: true

module Uchujin
  class Occurrence < ApplicationRecord
    self.table_name = "uchujin_occurrences"

    belongs_to :fault, class_name: "Uchujin::Fault", inverse_of: :occurrences, counter_cache: :occurrences_count

    validates :occurred_at, presence: true

    scope :newest, -> { order(occurred_at: :desc) }

    def application_backtrace
      Array(backtrace_app)
    end

    def full_backtrace
      Array(backtrace)
    end

    def source_context
      Array(source_context_lines)
    end
  end
end
