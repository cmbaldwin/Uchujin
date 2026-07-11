# frozen_string_literal: true

module Uchujin
  class ApplicationMailer < ActionMailer::Base
    default from: -> { Uchujin.configuration.notification_email.presence || "uchujin@localhost" }
    layout "uchujin/mailer"
  end
end
