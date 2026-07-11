# frozen_string_literal: true

require "digest"

module Uchujin
  # Builds a stable fingerprint from exception class + cleaned backtrace + component.
  module Fingerprint
    module_function

    def generate(class_name:, backtrace:, component: "web")
      cleaned = BacktraceCleaner.normalize(Array(backtrace))
      # Prefer application frames; fall back to full cleaned stack
      frames = cleaned.select { |l| l.include?("[PROJECT_ROOT]") }
      frames = cleaned.first(10) if frames.empty?
      digest_source = [ class_name, component, *frames ].join("\n")
      Digest::SHA256.hexdigest(digest_source)
    end
  end
end
