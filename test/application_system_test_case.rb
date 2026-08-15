require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  self.fixture_table_names = []
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ] do |options|
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--no-sandbox")
  end
end
