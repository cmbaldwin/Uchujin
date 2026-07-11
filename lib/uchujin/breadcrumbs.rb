# frozen_string_literal: true

module Uchujin
  # Ring buffer of typed events for the current request/job.
  module Breadcrumbs
    module_function

    def store
      if defined?(RequestStore)
        RequestStore.store[:uchujin_breadcrumbs] ||= []
      else
        Thread.current[:uchujin_breadcrumbs] ||= []
      end
    end

    def clear!
      if defined?(RequestStore)
        RequestStore.store[:uchujin_breadcrumbs] = []
      else
        Thread.current[:uchujin_breadcrumbs] = []
      end
      @started_at = monotonic_now
    end

    def add(type:, message:, metadata: {})
      @started_at ||= monotonic_now
      store << {
        type: type.to_s,
        message: message.to_s.truncate(500),
        metadata: metadata,
        relative_ms: ((monotonic_now - @started_at) * 1000).round(1),
        at: Time.current.iso8601(3)
      }
      limit = Uchujin.configuration.breadcrumb_limit
      store.shift while store.size > limit
    end

    def current
      store.dup
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
