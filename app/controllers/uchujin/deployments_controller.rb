# frozen_string_literal: true

module Uchujin
  class DeploymentsController < ApplicationController
    def index
      @deployments = Deployment.newest.limit(100)
    end

    def show
      @deployment = Deployment.find(params[:id])
      # Faults first seen around this deploy window
      window_start = @deployment.deployed_at - 5.minutes
      window_end = @deployment.deployed_at + 2.hours
      @faults = Fault.where(first_seen_at: window_start..window_end).recent.limit(50)
    end
  end
end
