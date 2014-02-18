module ApiResource

  #
  # Module for holding onto a collection of classes that
  # add relatively simple behavior to conditions and/or associations
  #
  # @author [ejlangev]
  #
  module Decorators

    extend ActiveSupport::Autoload

    autoload :AsyncDecorator
    autoload :CachingDecorator

  end

end
