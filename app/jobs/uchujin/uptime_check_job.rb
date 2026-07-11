# frozen_string_literal: true

require "net/http"
require "uri"

module Uchujin
  class UptimeCheckJob < ApplicationJob
    queue_as :uchujin

    # urls: array of URL strings to probe
    def perform(urls = nil)
      list = Array(urls).presence || default_urls
      list.each { |url| check(url) }
    end

    private

    def default_urls
      # Host can set via ENV; empty means no-op
      ENV.fetch("UCHUJIN_UPTIME_URLS", "").split(",").map(&:strip).reject(&:blank?)
    end

    def check(url)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 10
      path = uri.request_uri.presence || "/"
      response = http.request(Net::HTTP::Get.new(path))
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      status = response.code.to_i.between?(200, 399) ? "up" : "down"

      UptimeCheck.create!(
        url: url,
        status: status,
        response_time_ms: elapsed_ms,
        status_code: response.code.to_i,
        checked_at: Time.current
      )
    rescue => e
      UptimeCheck.create!(
        url: url,
        status: "down",
        error_message: "#{e.class}: #{e.message}".truncate(500),
        checked_at: Time.current
      )
    end
  end
end
