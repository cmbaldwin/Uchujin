# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class PingCheckIn < Tool
        tool_name "ping_check_in"
        description "Record a heartbeat ping for a named check-in (creates if missing)."
        input_schema(
          type: "object",
          properties: {
            name: { type: "string" },
            expected_every_seconds: { type: "integer", minimum: 1 }
          },
          required: [ "name" ],
          additionalProperties: false
        )

        def self.call(name:, expected_every_seconds: nil, **_)
          check_in = CheckIn.find_or_initialize_by(name: name.to_s)
          check_in.expected_every_seconds = expected_every_seconds if expected_every_seconds.present?
          check_in.ping!
          { ok: true, check_in: Serializers.check_in(check_in) }
        end
      end
    end
  end
end
