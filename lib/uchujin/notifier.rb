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
      send_slack
      send_webhook
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

    def send_slack
      url = @config.slack_webhook_url
      return if url.blank?

      body = {
        text: "*[#{@fault.environment}] #{@fault.class_name}*: #{@fault.message.to_s.truncate(200)}\n" \
              "Occurrences: #{@fault.occurrences_count} · Component: #{@fault.component}"
      }
      post_json(url, body)
    end

    def send_webhook
      url = @config.webhook_url
      return if url.blank?

      post_json(url, {
        event: "fault.occurrence",
        fault_id: @fault.id,
        fingerprint: @fault.fingerprint,
        class_name: @fault.class_name,
        message: @fault.message,
        environment: @fault.environment,
        occurrences_count: @fault.occurrences_count,
        occurrence_id: @occurrence.id
      })
    end

    def post_json(url, body)
      require "net/http"
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      req = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
      req.body = body.to_json
      http.request(req)
    rescue => e
      warn "[Uchujin] webhook failed: #{e.message}"
    end
  end
end
