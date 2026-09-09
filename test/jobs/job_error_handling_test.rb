# frozen_string_literal: true

require "test_helper"

class JobErrorHandlingLeakJob < ActiveJob::Base
  include Uchujin::JobErrorHandling

  cattr_accessor :seen_breadcrumbs, :seen_context

  def perform
    self.class.seen_breadcrumbs = Uchujin::Breadcrumbs.current
    self.class.seen_context = Uchujin.context
  end
end

class FailingLeakJob < ActiveJob::Base
  include Uchujin::JobErrorHandling

  def perform
    raise RuntimeError, "job blew up"
  end
end

class JobErrorHandlingTest < ActiveJob::TestCase
  test "around_perform starts with clean breadcrumbs and context" do
    Uchujin.leave_breadcrumb("leaked from previous work")
    Uchujin.context(stale_key: "stale")

    JobErrorHandlingLeakJob.perform_now

    assert_empty JobErrorHandlingLeakJob.seen_breadcrumbs
    assert_empty JobErrorHandlingLeakJob.seen_context
  end

  test "around_perform still reports job errors" do
    assert_enqueued_with(job: Uchujin::ProcessNoticeJob) do
      assert_raises(RuntimeError) { FailingLeakJob.perform_now }
    end
  end
end
