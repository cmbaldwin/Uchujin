# frozen_string_literal: true

module Uchujin
  # Ring buffer of typed events for the current request/job.
  module Breadcrumbs
    module_function

    def bucket
      if defined?(RequestStore)
        RequestStore.store[:uchujin_breadcrumbs] ||= { events: [], started_at: monotonic_now }
      else
        Thread.current[:uchujin_breadcrumbs] ||= { events: [], started_at: monotonic_now }
      end
    end

    def store
      bucket[:events]
    end

    def clear!
      if defined?(RequestStore)
        RequestStore.store[:uchujin_breadcrumbs] = { events: [], started_at: monotonic_now }
      else
        Thread.current[:uchujin_breadcrumbs] = { events: [], started_at: monotonic_now }
      end
    end

    def add(type:, message:, metadata: {})
      b = bucket
      b[:started_at] ||= monotonic_now
      b[:events] << {
        type: type.to_s,
        message: message.to_s.truncate(500),
        metadata: metadata,
        relative_ms: ((monotonic_now - b[:started_at]) * 1000).round(1),
        at: Time.current.iso8601(3)
      }
      limit = Uchujin.configuration.breadcrumb_limit
      b[:events].shift while b[:events].size > limit
    end

    def current
      store.dup
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
