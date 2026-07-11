# frozen_string_literal: true

module Uchujin
  module Api
    class CheckInsController < BaseController
      def ping
        check_in = CheckIn.find_or_initialize_by(name: params[:name])
        check_in.expected_every_seconds ||= params[:expected_every_seconds]
        check_in.ping!
        render json: {
          name: check_in.name,
          last_seen_at: check_in.last_seen_at,
          ping_count: check_in.ping_count
        }
      end
    end
  end
end
