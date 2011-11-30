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
require 'colorize'

module ApiResource
  
  extend ActiveSupport::Autoload
  
  autoload :Associations
  autoload :AssociationActivation
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
  autoload :Scopes
  autoload :Validations
  
  
  mattr_writer :logger
  mattr_accessor :raise_missing_definition_error; self.raise_missing_definition_error = false

  DEFAULT_TIMEOUT = 10 # seconds
  
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
  # set token
  def self.token=(new_token)
    ApiResource::Base.token = new_token
  end
  # get token
  def self.token
    ApiResource::Base.token
  end
  # Run a block with a given token - useful for AroundFilters
  def self.with_token(new_token, &block)
    old_token = self.token
    begin
      self.token = new_token
      yield
    ensure
      self.token = old_token
    end
  end
  
  # delegated to Base
  def self.reset_connection
    ApiResource::Base.reset_connection
  end

  # set the timeout val and reset the connection
  def self.timeout=(val)
    @timeout = val
    self.reset_connection
    val
  end
  
  # Getter for timeout
  def self.timeout
    @timeout ||= DEFAULT_TIMEOUT
  end

  # set the timeout val and reset the connection
  def self.open_timeout=(val)
    @open_timeout = val
    self.reset_connection
    val
  end
  
  # Getter for timeout
  def self.open_timeout
    @open_timeout ||= DEFAULT_TIMEOUT
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