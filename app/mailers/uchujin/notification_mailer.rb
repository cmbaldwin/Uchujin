# frozen_string_literal: true

module Uchujin
  class NotificationMailer < ApplicationMailer
    def fault_notice(fault, occurrence, email)
      @fault = fault
      @occurrence = occurrence
      @app_name = Uchujin.configuration.app_name
      mail(
        to: email,
        subject: "[#{@app_name}] #{fault.class_name}: #{fault.message.to_s.truncate(80)}"
      )
    end
  end
end
