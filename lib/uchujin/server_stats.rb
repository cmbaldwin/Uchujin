# frozen_string_literal: true

module Uchujin
  module ServerStats
    module_function

    def capture
      {
        hostname: Socket.gethostname,
        pid: Process.pid,
        revision: Uchujin.configuration.revision,
        ruby: RUBY_VERSION,
        rails: Rails.version,
        ram_mb: rss_mb,
        load_average: load_avg
      }
    rescue
      { hostname: "unknown", pid: Process.pid }
    end

    def rss_mb
      if File.readable?("/proc/#{Process.pid}/status")
        status = File.read("/proc/#{Process.pid}/status")
        if status =~ /VmRSS:\s+(\d+)/
          (Regexp.last_match(1).to_i / 1024.0).round(1)
        end
      elsif RUBY_PLATFORM.include?("darwin")
        # ps rss is in KB on macOS
        out = `ps -o rss= -p #{Process.pid}`.to_s.strip
        (out.to_i / 1024.0).round(1) if out.present?
      end
    rescue
      nil
    end

    def load_avg
      if File.readable?("/proc/loadavg")
        File.read("/proc/loadavg").split.take(3).map(&:to_f)
      else
        # macOS
        out = `sysctl -n vm.loadavg 2>/dev/null`.to_s
        out.scan(/[\d.]+/).first(3).map(&:to_f)
      end
    rescue
      []
    end
  end
end
