# frozen_string_literal: true

module Uchujin
  class Comment < ApplicationRecord
    self.table_name = "uchujin_comments"

    belongs_to :fault, class_name: "Uchujin::Fault", inverse_of: :comments

    validates :body, presence: true

    scope :newest, -> { order(created_at: :desc) }
  end
end
