if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start

  Dir[Rails.root.join('lib/*.rb')].each {|file| load file }
end

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rails.application.eager_load! if ENV['COVERAGE']

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

def web_fixture(name)
  File.new(File.join(File.expand_path('../webfixtures', __FILE__), name))
end

require 'webmock/minitest'
WebMock.disable_net_connect!
require 'mocha/minitest'
