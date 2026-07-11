# frozen_string_literal: true

module Uchujin
  class Configuration
    # Host auth: run as a before_action in the engine
    attr_accessor :authenticate_with
    # Callable that returns the current user (for assignee/comments)
    attr_accessor :current_user

    # Environments that should capture errors (default: all except test)
    attr_accessor :environments

    # Retention
    attr_accessor :retention_period
    attr_accessor :resolved_retention_period
    attr_accessor :pruning_enabled

    # Capture
    attr_accessor :ignored_exceptions
    attr_accessor :breadcrumb_limit
    attr_accessor :source_context_lines

    # Deploy / revision
    attr_accessor :revision
    attr_accessor :deploy_token

    # Notifications
    attr_accessor :notification_email
    attr_accessor :mailer_from
    attr_accessor :slack_webhook_url
    attr_accessor :webhook_url
    attr_accessor :notify_on_every_occurrence
    attr_accessor :notification_rate_limit

    # Jobs
    attr_accessor :queue_name

    # UI
    attr_accessor :app_name

    def initialize
      @environments = %w[development production staging]
      @retention_period = 90.days
      @resolved_retention_period = 30.days
      @pruning_enabled = false
      @ignored_exceptions = %w[
        ActionController::RoutingError
        ActiveRecord::RecordNotFound
        AbstractController::ActionNotFound
      ]
      @breadcrumb_limit = 50
      @source_context_lines = 5
      @revision = ENV["GIT_REVISION"] || ENV["KAMAL_VERSION"] || ENV["HEROKU_SLUG_COMMIT"]
      @deploy_token = ENV["UCHUJIN_DEPLOY_TOKEN"]
      @notify_on_every_occurrence = false
      @notification_rate_limit = 5.minutes
      @queue_name = :default
      @mailer_from = ENV["UCHUJIN_MAILER_FROM"] || "uchujin@localhost"
      @app_name = "Uchujin"
    end

    def authenticate(&block)
      @authenticate_with = block
    end

    def current_user_method(&block)
      @current_user = block
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
