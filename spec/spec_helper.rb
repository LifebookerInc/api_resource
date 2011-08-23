$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bundler'
require 'api_resource'
require 'simplecov'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Bundler.require(:default, :development)
Debugger.start

SimpleCov.start

SimpleCov.at_exit do
  SimpleCov.result.format!
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
#ApiResource.load_mocks_and_factories
ApiResource.site = 'http://localhost:3000'
ApiResource.format = :json
ApiResource.load_mocks_and_factories

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}



RSpec.configure do |config|
  
end
