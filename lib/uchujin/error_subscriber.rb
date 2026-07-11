# frozen_string_literal: true

module Uchujin
  # Subscribes to ActiveSupport::ErrorReporter (Rails.error.report / Rails.error.handle)
  class ErrorSubscriber
    def report(error, handled:, severity:, context:, source: nil)
      return if handled && severity == :info
      return unless Uchujin.configuration.environments.map(&:to_s).include?(Rails.env.to_s)

      Uchujin.notify(
        error,
        context: (context || {}).merge(handled: handled, severity: severity, source: source),
        component: source.to_s.presence || "reporter"
      )
    end
  end
end
