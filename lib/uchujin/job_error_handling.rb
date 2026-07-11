# frozen_string_literal: true

module Uchujin
  # Captures job failures without stealing host `retry_on` / `discard_on` handlers.
  module JobErrorHandling
    extend ActiveSupport::Concern

    included do
      around_perform do |job, block|
        block.call
      rescue StandardError => exception
        unless job.class.name.to_s.start_with?("Uchujin::")
          Uchujin.notify(
            exception,
            context: {
              job_class: job.class.name,
              job_id: job.job_id,
              queue: job.queue_name,
              arguments: Array(job.arguments).map { |a| a.inspect.to_s.truncate(200) }
            },
            component: "job"
          )
        end
        raise
      end
    end
  end
end
