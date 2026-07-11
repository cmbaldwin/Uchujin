# frozen_string_literal: true

require "test_helper"

class UchujinTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "has a version number" do
    assert Uchujin::VERSION
  end

  test "configuration yields defaults" do
    assert_includes Uchujin.configuration.ignored_exceptions, "ActionController::RoutingError"
    assert_equal 50, Uchujin.configuration.breadcrumb_limit
  end

  test "fingerprint is stable for same stack" do
    bt = [ "#{Rails.root}/app/models/order.rb:10:in `charge!`", "/gems/rails/foo.rb:1" ]
    a = Uchujin::Fingerprint.generate(class_name: "RuntimeError", backtrace: bt, component: "web")
    b = Uchujin::Fingerprint.generate(class_name: "RuntimeError", backtrace: bt, component: "web")
    assert_equal a, b
    c = Uchujin::Fingerprint.generate(class_name: "RuntimeError", backtrace: bt, component: "job")
    refute_equal a, c
  end

  test "notify enqueues ProcessNoticeJob" do
    assert_enqueued_with(job: Uchujin::ProcessNoticeJob) do
      Uchujin.notify(RuntimeError.new("boom"))
    end
  end

  test "ignored exceptions are skipped" do
    assert_no_enqueued_jobs only: Uchujin::ProcessNoticeJob do
      Uchujin.notify(ActiveRecord::RecordNotFound.new("missing"))
    end
  end

  test "context and breadcrumbs helpers" do
    Uchujin::Context.clear!
    Uchujin::Breadcrumbs.clear!
    Uchujin.context(user_id: 42)
    Uchujin.leave_breadcrumb("step one")
    assert_equal "42", Uchujin.context["user_id"].to_s
    assert_equal 1, Uchujin::Breadcrumbs.current.size
  end
end
