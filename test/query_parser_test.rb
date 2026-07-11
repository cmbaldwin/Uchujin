# frozen_string_literal: true

require "test_helper"

class QueryParserTest < ActiveSupport::TestCase
  setup do
    Uchujin::Fault.create!(
      fingerprint: "a" * 64,
      class_name: "RuntimeError",
      message: "payment failed",
      component: "web",
      environment: "production",
      status: "unresolved",
      tags: [ "payments" ],
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    Uchujin::Fault.create!(
      fingerprint: "b" * 64,
      class_name: "NoMethodError",
      message: "nil charge",
      component: "job",
      environment: "staging",
      status: "resolved",
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
  end

  test "filters by status" do
    scope = Uchujin::QueryParser.new("is:unresolved").apply(Uchujin::Fault.all)
    assert_equal 1, scope.count
    assert_equal "RuntimeError", scope.first.class_name
  end

  test "filters by environment" do
    scope = Uchujin::QueryParser.new("environment:staging").apply(Uchujin::Fault.all)
    assert_equal [ "NoMethodError" ], scope.pluck(:class_name)
  end

  test "free text search" do
    scope = Uchujin::QueryParser.new("payment").apply(Uchujin::Fault.all)
    assert_equal 1, scope.count
  end

  test "filters by tag" do
    scope = Uchujin::QueryParser.new("tag:payments").apply(Uchujin::Fault.all)
    assert_equal 1, scope.count
    assert_equal "RuntimeError", scope.first.class_name
  end
end
