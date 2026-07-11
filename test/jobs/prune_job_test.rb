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
end
