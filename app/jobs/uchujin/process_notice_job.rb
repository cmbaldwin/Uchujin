# frozen_string_literal: true

module Uchujin
  class ProcessNoticeJob < ApplicationJob
    queue_as :uchujin

    def perform(notice)
      notice = notice.deep_stringify_keys
      backtrace = Array(notice["backtrace"])
      class_name = notice["class_name"].to_s
      component = notice["component"].presence || "web"
      environment = notice["environment"].presence || Rails.env.to_s

      fingerprint = Fingerprint.generate(
        class_name: class_name,
        backtrace: backtrace,
        component: component
      )

      fault = Fault.find_or_initialize_by(fingerprint: fingerprint)
      is_new = fault.new_record?
      now = parse_time(notice["occurred_at"]) || Time.current

      fault.class_name = class_name
      fault.message = notice["message"].to_s.truncate(5000)
      fault.component = component
      fault.environment = environment
      fault.revision = notice["revision"]
      fault.first_seen_at ||= now
      fault.last_seen_at = now
      fault.sample_context = notice["context"] if fault.sample_context.blank? || is_new

      # Reopen resolved faults on new activity
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

      # counter_cache may lag if occurrences_count was 0 on create
      fault.reload
      Notifier.notify_fault(fault, occurrence) if should_notify?(fault, is_new)
    rescue => e
      warn "[Uchujin] ProcessNoticeJob failed: #{e.class}: #{e.message}"
      raise
    end

    private

    def should_notify?(fault, is_new)
      return false if fault.ignored?
      return true if is_new
      return true if Uchujin.configuration.notify_on_every_occurrence
      true # first occurrence after reopen or subsequent — rate limit handles noise
    end

    def parse_time(value)
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
      Time.zone.parse(value.to_s) if value.present?
    rescue
      nil
    end
  end
end
