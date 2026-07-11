# frozen_string_literal: true

require "uchujin/version"
require "uchujin/engine"

module Uchujin
  class << self
    # Public capture entry-point used by middleware, ErrorReporter, ActiveJob.
    def notify(exception, context: {}, request: nil, component: "web", env: nil)
      return unless enabled?
      return if ignored?(exception)
      # Prevent double capture (middleware + ErrorSubscriber) and recursive notify
      return if Thread.current[:uchujin_notifying]
      # Prevent double capture of the SAME exception object via two capture paths
      # for one failure (e.g. ErrorCatcher middleware + Rails.error subscriber for
      # one unhandled web request, or around_perform + Rails.error for one job
      # attempt). Retried jobs raise a NEW exception object per attempt, so retries
      # are still captured — that's intended, not a bug this guard should block.
      return if exception.instance_variable_defined?(:@__uchujin_reported__)
      begin
        exception.instance_variable_set(:@__uchujin_reported__, true)
      rescue FrozenError
        # frozen exception objects can't be tagged; accept possible double capture
      end

      Thread.current[:uchujin_notifying] = true
      notice = {
        class_name: exception.class.name,
        message: exception.message.to_s.truncate(5000),
        backtrace: exception.backtrace || [],
        cause: serialize_cause(exception.cause),
        context: Context.capture.merge(context.stringify_keys),
        breadcrumbs: Breadcrumbs.current,
        server_stats: ServerStats.capture,
        component: component.to_s,
        environment: Rails.env.to_s,
        revision: configuration.revision,
        params: request ? safe_params(request) : {},
        request_metadata: request ? request_metadata(request) : {},
        client_info: request ? client_info(request) : {},
        occurred_at: Time.current.iso8601
      }

      ProcessNoticeJob.perform_later(notice)
    rescue => e
      # Never let Uchujin take down the host.
      warn "[Uchujin] failed to enqueue notice: #{e.class}: #{e.message}"
    ensure
      Thread.current[:uchujin_notifying] = false
    end

    def enabled?
      configuration.environments.map(&:to_s).include?(Rails.env.to_s)
    end

    def ignored?(exception)
      configuration.ignored_exceptions.any? do |name|
        exception.class.name == name || exception.class.ancestors.any? { |a| a.name == name }
      end
    end

    def context(hash = nil)
      if hash
        Context.set(hash)
      else
        Context.capture
      end
    end

    def leave_breadcrumb(message, type: "custom", metadata: {})
      Breadcrumbs.add(type: type, message: message, metadata: metadata)
    end

    private

    def serialize_cause(cause, depth = 0)
      return nil if cause.nil? || depth > 5
      {
        class_name: cause.class.name,
        message: cause.message.to_s.truncate(2000),
        backtrace: cause.backtrace || [],
        cause: serialize_cause(cause.cause, depth + 1)
      }
    end

    def safe_params(request)
      params = request.respond_to?(:filtered_parameters) ? request.filtered_parameters : request.params
      params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
      deep_truncate(params)
    rescue
      {}
    end

    def request_metadata(request)
      {
        url: request.original_url.to_s.truncate(2000),
        method: request.request_method,
        path: request.fullpath.to_s.truncate(1000),
        controller: request.params["controller"],
        action: request.params["action"],
        format: request.format&.to_s,
        referrer: request.referer.to_s.truncate(1000)
      }
    end

    def client_info(request)
      {
        ip: request.remote_ip,
        user_agent: request.user_agent.to_s.truncate(500),
        session_id: (request.session.id.to_s if request.respond_to?(:session) && request.session.respond_to?(:id))
      }
    end

    def deep_truncate(obj, max = 500)
      case obj
      when Hash
        obj.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_truncate(v, max) }
      when Array
        obj.first(50).map { |v| deep_truncate(v, max) }
      when String
        obj.truncate(max)
      else
        obj
      end
    end
  end
end
