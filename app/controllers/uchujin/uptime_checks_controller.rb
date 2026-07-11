# frozen_string_literal: true

module Uchujin
  class UptimeChecksController < ApplicationController
    def index
      @latest = UptimeCheck.order(checked_at: :desc).limit(200).group_by(&:url).transform_values(&:first)
      @history = UptimeCheck.order(checked_at: :desc).limit(100)
    end
  end
end
