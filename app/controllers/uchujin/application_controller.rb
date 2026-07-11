# frozen_string_literal: true

module Uchujin
  class ApplicationController < ActionController::Base
    layout "uchujin/application"
    protect_from_forgery with: :exception

    before_action :run_host_authentication
    helper Uchujin::ApplicationHelper

    private

    def run_host_authentication
      auth = Uchujin.configuration.authenticate_with
      if auth.nil?
        # Fail closed in production so a forgotten initializer never exposes the UI.
        if Rails.env.production?
          render plain: "Uchujin authentication is not configured. " \
                        "Set config.authenticate in config/initializers/uchujin.rb",
                 status: :forbidden
        end
        return
      end

      if auth.arity == 1
        instance_exec(self, &auth)
      else
        instance_exec(&auth)
      end
    end

    def uchujin_current_user
      fn = Uchujin.configuration.current_user
      return nil if fn.nil?

      if fn.arity == 1
        instance_exec(self, &fn)
      else
        instance_exec(&fn)
      end
    end
    helper_method :uchujin_current_user

    def uchujin_user_id
      user = uchujin_current_user
      return nil if user.nil?
      user.respond_to?(:id) ? user.id : user
    end

    def uchujin_user_name
      user = uchujin_current_user
      return "anonymous" if user.nil?
      if user.respond_to?(:name) && user.name.present?
        user.name
      elsif user.respond_to?(:email)
        user.email
      elsif user.respond_to?(:to_s)
        user.to_s
      else
        "user##{user.try(:id)}"
      end
    end
  end
end
