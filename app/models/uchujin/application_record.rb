# frozen_string_literal: true

module Uchujin
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
