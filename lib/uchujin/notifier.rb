# frozen_string_literal: true

module Uchujin
  # Sends notifications with de-dup + rate limiting.
  class Notifier
    def self.notify_fault(fault, occurrence)
      new(fault, occurrence).deliver
    end

    def initialize(fault, occurrence)
      @fault = fault
      @occurrence = occurrence
      @config = Uchujin.configuration
    end

    def deliver
      return if @fault.ignored?
      return if @fault.resolved? && !@config.notify_on_every_occurrence
      return if rate_limited?

      send_email
      mark_notified!
    end

    private

    def rate_limited?
      return false if @config.notify_on_every_occurrence
      last = @fault.last_notified_at
      limit = @config.notification_rate_limit
      return false if last.blank? || limit.blank?
      last > limit.ago
    end

    def mark_notified!
      @fault.update_columns(last_notified_at: Time.current)
    end

    def send_email
      email = @config.notification_email
      return if email.blank?

      Uchujin::NotificationMailer.fault_notice(@fault, @occurrence, email).deliver_later
    rescue => e
      warn "[Uchujin] email notify failed: #{e.message}"
    end
  end
end
