require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "application health endpoint responds successfully" do
    get rails_health_check_path

    assert_response :success
  end
end
