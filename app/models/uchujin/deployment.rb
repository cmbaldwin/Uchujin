# frozen_string_literal: true

module Uchujin
  class Deployment < ApplicationRecord
    self.table_name = "uchujin_deployments"

    validates :sha, presence: true
    validates :environment, presence: true

    scope :newest, -> { order(deployed_at: :desc) }

    def short_sha
      sha.to_s[0, 7]
    end
  end
end
