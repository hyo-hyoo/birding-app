ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Check the resolved configuration before Rails prepares or clears test tables.
database = ActiveRecord::Base.connection_db_config.configuration_hash
unless Rails.env.test? && database[:host] == "127.0.0.1" && database[:port].to_i == 3307 &&
    database[:username] == "birding_app" && database[:database] == "birding_app_test"
  raise "Tests require the approved local MySQL 8.4 test database"
end

require "rails/test_help"

module ActiveSupport
  class TestCase
    # Windows shares one MySQL test schema. Keep fixtures and global request/time
    # state isolated; explicit concurrency tests use independent connections.
    parallelize(workers: 1, with: :threads)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
