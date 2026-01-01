ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors) # Disabled for Windows compatibility

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # fixtures :all # Temporarily disabled due to fixture loading errors

    # Add more helper methods to be used by all tests here...
  end
end
