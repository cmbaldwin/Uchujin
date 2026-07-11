# frozen_string_literal: true

module Uchujin
  class ApplicationMailer < ActionMailer::Base
    default from: -> { Uchujin.configuration.mailer_from.presence || "uchujin@localhost" }
    layout "uchujin/mailer"
  end
end
