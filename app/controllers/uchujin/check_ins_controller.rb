# frozen_string_literal: true

module Uchujin
  class CheckInsController < ApplicationController
    def index
      @check_ins = CheckIn.order(:name)
    end

    def create
      check_in = CheckIn.find_or_initialize_by(name: params.require(:check_in)[:name])
      check_in.expected_every_seconds = params[:check_in][:expected_every_seconds]
      check_in.save!
      redirect_to check_ins_path, notice: "Check-in registered."
    end
  end
end
