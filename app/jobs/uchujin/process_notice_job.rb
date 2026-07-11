# frozen_string_literal: true

module Uchujin
  class ProcessNoticeJob < ApplicationJob
    # Use default queue so host SolidQueue/Sidekiq workers pick it up without
    # requiring a dedicated "uchujin" queue configuration.
    queue_as do
      Uchujin.configuration.queue_name
    end

    def perform(notice)
      notice = notice.deep_stringify_keys
      backtrace = Array(notice["backtrace"])
      class_name = notice["class_name"].to_s
      component = notice["component"].presence || "web"
      environment = notice["environment"].presence || Rails.env.to_s
      now = parse_time(notice["occurred_at"]) || Time.current

      fingerprint = Fingerprint.generate(
        class_name: class_name,
        backtrace: backtrace,
        component: component
      )

      fault = find_or_create_fault!(
        fingerprint: fingerprint,
        class_name: class_name,
        message: notice["message"].to_s.truncate(5000),
        component: component,
        environment: environment,
        revision: notice["revision"],
        context: notice["context"],
        now: now
      )

      is_new = fault.previous_changes.key?("id") || fault.occurrences_count.to_i.zero?

      fault.class_name = class_name
      fault.message = notice["message"].to_s.truncate(5000)
      fault.component = component
      fault.environment = environment
      fault.revision = notice["revision"] if notice["revision"].present?
      fault.first_seen_at ||= now
      fault.last_seen_at = now
      fault.sample_context = notice["context"] if fault.sample_context.blank?

      if fault.resolved?
        fault.status = "unresolved"
        fault.resolved_at = nil
      end

      fault.save!

      occurrence = fault.occurrences.create!(
        occurred_at: now,
        message: notice["message"].to_s.truncate(5000),
        backtrace: BacktraceCleaner.normalize(backtrace),
        backtrace_app: BacktraceCleaner.application_only(backtrace),
        source_context_lines: BacktraceCleaner.with_source_context(backtrace),
        cause: notice["cause"],
        context: notice["context"] || {},
        breadcrumbs: notice["breadcrumbs"] || [],
        server_stats: notice["server_stats"] || {},
        params: notice["params"] || {},
        request_metadata: notice["request_metadata"] || {},
        client_info: notice["client_info"] || {},
        component: component,
        environment: environment,
        revision: notice["revision"]
      )

      fault.reload
      Notifier.notify_fault(fault, occurrence) if should_notify?(fault, is_new)
    rescue => e
      warn "[Uchujin] ProcessNoticeJob failed: #{e.class}: #{e.message}"
      raise
    end

    private

    def find_or_create_fault!(fingerprint:, class_name:, message:, component:, environment:, revision:, context:, now:)
      existing = Fault.find_by(fingerprint: fingerprint)
      return existing if existing

      Fault.create!(
        fingerprint: fingerprint,
        class_name: class_name,
        message: message,
        component: component,
        environment: environment,
        revision: revision,
        status: "unresolved",
        first_seen_at: now,
        last_seen_at: now,
        sample_context: context || {}
      )
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      # Concurrent create of the same fingerprint (unique index / uniqueness validation)
      Fault.find_by!(fingerprint: fingerprint)
    end

    def should_notify?(fault, is_new)
      return false if fault.ignored?
      return true if is_new
      return true if Uchujin.configuration.notify_on_every_occurrence

      true
    end

    def parse_time(value)
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
      Time.zone.parse(value.to_s) if value.present?
    rescue
      nil
    end
  end
end
