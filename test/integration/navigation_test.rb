# frozen_string_literal: true

require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  include Uchujin::Engine.routes.url_helpers

  def setup
    @routes = Uchujin::Engine.routes
  end

  test "dashboard renders" do
    get root_path
    assert_response :success
    assert_match(/Dashboard/, response.body)
  end

  test "faults index renders" do
    get faults_path
    assert_response :success
  end

  test "fault show renders after notice processed" do
    Uchujin::ProcessNoticeJob.perform_now(
      "class_name" => "NoMethodError",
      "message" => "undefined method `foo'",
      "backtrace" => [ "#{Rails.root}/app/controllers/home_controller.rb:3:in `index`" ],
      "component" => "web",
      "environment" => "test",
      "occurred_at" => Time.current.iso8601
    )
    fault = Uchujin::Fault.last
    get fault_path(fault)
    assert_response :success
    assert_match(/NoMethodError/, response.body)
  end

  test "resolve fault" do
    Uchujin::ProcessNoticeJob.perform_now(
      "class_name" => "RuntimeError",
      "message" => "x",
      "backtrace" => [ "#{Rails.root}/lib/x.rb:1" ],
      "component" => "web",
      "environment" => "test",
      "occurred_at" => Time.current.iso8601
    )
    fault = Uchujin::Fault.last
    post resolve_fault_path(fault)
    assert_redirected_to fault_path(fault)
    assert fault.reload.resolved?
  end

  test "deployments api creates record" do
    post api_deployments_path,
         params: { sha: "abc123def", environment: "production", user: "kamal" },
         headers: { "Authorization" => "Bearer test-deploy-token" },
         as: :json
    assert_response :created
    assert_equal "abc123def", Uchujin::Deployment.last.sha
  end

  test "deployments api rejects bad token" do
    post api_deployments_path,
         params: { sha: "abc", environment: "production" },
         headers: { "Authorization" => "Bearer wrong" },
         as: :json
    assert_response :unauthorized
  end

  test "deployments api falls back to now on invalid deployed_at" do
    post api_deployments_path,
         params: { sha: "abc123def", environment: "production", deployed_at: "not-a-date" },
         headers: { "Authorization" => "Bearer test-deploy-token" },
         as: :json
    assert_response :created
    assert_not_nil Uchujin::Deployment.last.deployed_at

    post api_deployments_path,
         params: { sha: "def456abc", environment: "production", deployed_at: "2026-13-45" },
         headers: { "Authorization" => "Bearer test-deploy-token" },
         as: :json
    assert_response :created
  end

  test "check-in ping" do
    post api_check_in_ping_path(name: "nightly"),
         headers: { "Authorization" => "Bearer test-deploy-token" },
         as: :json
    assert_response :success
    assert_equal "nightly", Uchujin::CheckIn.last.name
    assert_equal 1, Uchujin::CheckIn.last.ping_count
  end

  test "check-in ping ignores garbage cadence" do
    post api_check_in_ping_path(name: "nightly"),
         params: { expected_every_seconds: "every hour or so" },
         headers: { "Authorization" => "Bearer test-deploy-token" },
         as: :json
    assert_response :success
    check_in = Uchujin::CheckIn.find_by!(name: "nightly")
    assert_nil check_in.expected_every_seconds
    assert_not check_in.overdue?
  end

  test "check-in ping records numeric cadence once" do
    post api_check_in_ping_path(name: "nightly"),
         params: { expected_every_seconds: "3600" },
         headers: { "Authorization" => "Bearer test-deploy-token" },
         as: :json
    assert_response :success
    assert_equal 3600, Uchujin::CheckIn.find_by!(name: "nightly").expected_every_seconds

    post api_check_in_ping_path(name: "nightly"),
         params: { expected_every_seconds: "60" },
         headers: { "Authorization" => "Bearer test-deploy-token" },
         as: :json
    assert_response :success
    assert_equal 3600, Uchujin::CheckIn.find_by!(name: "nightly").expected_every_seconds
  end
end
