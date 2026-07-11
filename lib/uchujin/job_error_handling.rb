# frozen_string_literal: true

module Uchujin
  module JobErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from(StandardError) do |exception|
        # Avoid recursive capture of Uchujin's own jobs
        unless self.class.name.to_s.start_with?("Uchujin::")
          Uchujin.notify(
            exception,
            context: {
              job_class: self.class.name,
              job_id: job_id,
              queue: queue_name,
              arguments: Array(arguments).map { |a| a.inspect.to_s.truncate(200) }
            },
            component: "job"
          )
        end
        raise
      end
    end
  end
end
