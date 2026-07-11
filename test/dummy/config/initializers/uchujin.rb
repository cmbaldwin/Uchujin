# frozen_string_literal: true

Uchujin.configure do |config|
  config.app_name = "Uchujin Dummy"
  config.environments = %w[development test production]
  # No auth in dummy — open UI for integration tests
  config.deploy_token = "test-deploy-token"
end
