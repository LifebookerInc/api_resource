require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext'
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
  autoload :Conditions
  autoload :Connection
  autoload :CustomMethods
  autoload :Decorators
  autoload :Formats
  autoload :Finders
  autoload :Local
  autoload :LogSubscriber
  autoload :Mocks
  autoload :ModelErrors
  autoload :Observing
  autoload :Scopes
  autoload :Serializer
  autoload :Typecast
  autoload :Validations

  require 'api_resource/railtie'

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

    Dir["#{File.dirname(__FILE__)}/../spec/support/requests/*.rb"].each {|f|
      require f
    }
    Dir["#{File.dirname(__FILE__)}/../spec/support/**/*.rb"].each {|f|
      require f
    }
  end

  class << self

    delegate :site, :site=, :format, :format=,
      :token, :token=, :timeout,
      :open_timeout,
      :reset_connection, :ttl, :ttl=,
      :to => "ApiResource::Base"

  end

  def self.cache(reset = false)
    @cache = nil if reset
    @cache ||= begin
        defined?(Rails) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new
      rescue
        ActiveSupport::Cache::MemoryStore.new
    end
  end

  # set the timeout val and reset the connection
  def self.timeout=(val)
    ApiResource::Base.timeout = val
    self.reset_connection
    val
  end

  # set the timeout val and reset the connection
  def self.open_timeout=(val)
    ApiResource::Base.open_timeout = val
    self.reset_connection
    val
  end
  self.timeout = self.open_timeout = DEFAULT_TIMEOUT

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

  def self.with_ttl(new_ttl, &block)
    old_ttl = self.ttl
    begin
      self.ttl = new_ttl
      yield
    ensure
      self.ttl = old_ttl
    end
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
