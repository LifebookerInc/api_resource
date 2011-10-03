require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/class/inheritable_attributes'
require 'api_resource/core_extensions'

require 'active_model'

require 'log4r'
require 'log4r/outputter/consoleoutputters'

require 'api_resource/exceptions'

require 'differ'

module ApiResource
  
  extend ActiveSupport::Autoload
  
  autoload :Associations
  autoload :Attributes
  autoload :Base
  autoload :Callbacks
  autoload :Connection
  autoload :CustomMethods
  autoload :Formats
  autoload :Local
  autoload :LogSubscriber
  autoload :Mocks
  autoload :ModelErrors
  autoload :Observing
  autoload :Validations
  
  
  mattr_writer :logger
  mattr_accessor :raise_missing_definition_error; self.raise_missing_definition_error = false
  
  # Load a fix for inflections for words ending in ess
  ActiveSupport::Inflector.inflections do |inflect|
    inflect.singular(/ess$/i, 'ess')
  end
  
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
  # logger
  def self.logger
    return @logger if @logger
    @logger = Log4r::Logger.new("api_resource")
    @logger.outputters = [Log4r::StdoutOutputter.new('console')]
    @logger.level = Log4r::INFO
    @logger
  end
  
  # Use this method to enable logging in the future
  # def self.logging(val = nil)
  #   return (@@logging || false) unless val
  #   return @@logging = val
  # end
  
end