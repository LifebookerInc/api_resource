require 'active_support'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/class/inheritable_attributes'
require 'api_resource/core_extensions'
require 'active_model'

require 'api_resource/exceptions'

module ApiResource
  
  extend ActiveSupport::Autoload
  
  autoload :Associations
  autoload :Attributes
  autoload :Base
  autoload :Connection
  autoload :CustomMethods
  autoload :Formats
  autoload :Observing
  autoload :Mocks
  autoload :ModelErrors
  autoload :Validations
  autoload :LogSubscriber
  
  def self.load_mocks_and_factories
    require 'hash_dealer'
    Mocks.clear_endpoints
    Mocks.init
    
    Dir["#{File.dirname(__FILE__)}/../spec/support/requests/*.rb"].each {|f| require f}
    Dir["#{File.dirname(__FILE__)}/../spec/support/**/*.rb"].each {|f| require f}
  end
  
  def self.site=(new_site)
    ApiResource::Base.site = new_site
  end
  
  def self.format=(new_format)
    ApiResource::Base.format = new_format
  end
  
  # Use this method to enable logging in the future
  # def self.logging(val = nil)
  #   return (@@logging || false) unless val
  #   return @@logging = val
  # end
  
end