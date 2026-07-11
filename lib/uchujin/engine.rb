# frozen_string_literal: true

require "uchujin/configuration"
require "uchujin/fingerprint"
require "uchujin/backtrace_cleaner"
require "uchujin/breadcrumbs"
require "uchujin/context"
require "uchujin/server_stats"
require "uchujin/query_parser"
require "uchujin/middleware/error_catcher"
require "uchujin/error_subscriber"
require "uchujin/job_error_handling"
require "uchujin/notifier"

module Uchujin
  class Engine < ::Rails::Engine
    isolate_namespace Uchujin

    config.generators do |g|
      g.test_framework :test_unit
      g.assets false
      g.helper false
    end

    initializer "uchujin.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/assets/stylesheets")
      end
    end

    initializer "uchujin.middleware" do |app|
      app.middleware.use Uchujin::Middleware::ErrorCatcher
    end

    initializer "uchujin.error_subscriber" do
      if defined?(ActiveSupport::ErrorReporter)
        Rails.error.subscribe(Uchujin::ErrorSubscriber.new)
      end
    end

    initializer "uchujin.active_job" do
      ActiveSupport.on_load(:active_job) do
        include Uchujin::JobErrorHandling
      end
    end

    initializer "uchujin.breadcrumbs" do
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        next if event.payload[:name].to_s == "SCHEMA"
        next if event.payload[:name].to_s.include?("Uchujin")
        Uchujin::Breadcrumbs.add(
          type: "query",
          message: event.payload[:sql].to_s.truncate(200),
          metadata: { duration_ms: event.duration.round(1), name: event.payload[:name] }
        )
      end

      ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        Uchujin::Breadcrumbs.add(
          type: "request",
          message: "#{event.payload[:method]} #{event.payload[:path]}",
          metadata: {
            status: event.payload[:status],
            controller: event.payload[:controller],
            action: event.payload[:action],
            duration_ms: event.duration.round(1)
          }
        )
      end
    end

    # Migrations are installed only via `rails generate uchujin:install`.
    # Do not append engine db/migrate — that double-runs CreateUchujinTables.
  end
end
