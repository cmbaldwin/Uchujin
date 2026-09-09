# frozen_string_literal: true

module Uchujin
  module Api
    class CheckInsController < BaseController
      def ping
        # find_or_initialize_by (not create_or_find_by!) — uniqueness validation
        # raises RecordInvalid on the second ping if we try to create-or-find.
        check_in = CheckIn.find_or_initialize_by(name: params[:name])
        cadence = params[:expected_every_seconds].to_s.to_i
        if check_in.expected_every_seconds.blank? && cadence.positive?
          check_in.expected_every_seconds = cadence
        end
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
