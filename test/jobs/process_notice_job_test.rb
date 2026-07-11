# frozen_string_literal: true

require "test_helper"

class ProcessNoticeJobTest < ActiveJob::TestCase
  test "creates fault and occurrence" do
    notice = {
      "class_name" => "RuntimeError",
      "message" => "kaboom",
      "backtrace" => [ "#{Rails.root}/app/models/x.rb:1:in `call`" ],
      "component" => "web",
      "environment" => "test",
      "context" => { "foo" => "bar" },
      "breadcrumbs" => [],
      "server_stats" => {},
      "params" => {},
      "request_metadata" => {},
      "client_info" => {},
      "occurred_at" => Time.current.iso8601
    }

    assert_difference -> { Uchujin::Fault.count } => 1, -> { Uchujin::Occurrence.count } => 1 do
      Uchujin::ProcessNoticeJob.perform_now(notice)
    end

    fault = Uchujin::Fault.last
    assert_equal "RuntimeError", fault.class_name
    assert_equal "kaboom", fault.message
    assert_equal "unresolved", fault.status
    assert_equal 1, fault.occurrences_count

    assert_no_difference -> { Uchujin::Fault.count } do
      assert_difference -> { Uchujin::Occurrence.count } => 1 do
        Uchujin::ProcessNoticeJob.perform_now(notice.merge("message" => "kaboom again"))
      end
    end
    fault.reload
    assert_equal 2, fault.occurrences_count
  end

  test "reopens resolved fault" do
    notice = {
      "class_name" => "ArgumentError",
      "message" => "bad",
      "backtrace" => [ "#{Rails.root}/app/services/pay.rb:5:in `run`" ],
      "component" => "web",
      "environment" => "test",
      "occurred_at" => Time.current.iso8601
    }
    Uchujin::ProcessNoticeJob.perform_now(notice)
    fault = Uchujin::Fault.last
    fault.resolve!
    assert fault.resolved?

    Uchujin::ProcessNoticeJob.perform_now(notice)
    fault.reload
    assert fault.unresolved?
  end
end
