# frozen_string_literal: true

require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "fault_notice squishes newlines out of the subject" do
    fault = Uchujin::Fault.create!(
      fingerprint: "subject-newline-test",
      class_name: "RuntimeError",
      message: "404: <!doctype html>\n<html>\n  <head></head>\n</html>",
      status: "unresolved",
      component: "job",
      environment: "test",
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    occurrence = fault.occurrences.create!(occurred_at: Time.current)

    mail = Uchujin::NotificationMailer.fault_notice(fault, occurrence, "cody@moab.jp")

    refute_match(/\n/, mail.subject)
  end
end
