# frozen_string_literal: true

require "test_helper"

class PruneJobTest < ActiveJob::TestCase
  test "deletes notifications older than retention but keeps recent ones" do
    Uchujin.configuration.pruning_enabled = true
    Uchujin.configuration.retention_period = 30.days

    old = Uchujin::Notification.create!(channel: "email", created_at: 60.days.ago)
    recent = Uchujin::Notification.create!(channel: "email", created_at: 1.day.ago)

    Uchujin::PruneJob.perform_now

    assert_not Uchujin::Notification.exists?(old.id)
    assert Uchujin::Notification.exists?(recent.id)
  end

  test "does nothing when pruning is disabled" do
    Uchujin.configuration.pruning_enabled = false
    Uchujin.configuration.retention_period = 30.days

    old = Uchujin::Notification.create!(channel: "email", created_at: 60.days.ago)

    Uchujin::PruneJob.perform_now

    assert Uchujin::Notification.exists?(old.id)
  end

  test "repairs drifted occurrences_count in one pass" do
    Uchujin.configuration.pruning_enabled = true

    fault = Uchujin::Fault.create!(
      fingerprint: "c" * 64,
      class_name: "RuntimeError",
      message: "boom",
      component: "web",
      environment: "test",
      status: "unresolved",
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    2.times do
      fault.occurrences.create!(occurred_at: Time.current, message: "boom")
    end
    Uchujin::Fault.where(id: fault.id).update_all(occurrences_count: 99)

    Uchujin::PruneJob.perform_now

    assert_equal 2, fault.reload.occurrences_count
  end
end
