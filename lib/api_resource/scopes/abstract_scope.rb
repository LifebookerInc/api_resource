module ApiResource

  module Scopes

    #
    # Superclass for scope objects that know how
    # to apply themselves and validate their arguments and
    # return the proper condition object
    #
    # @author [ejlangev]
    #
    class AbstractScope

      #
      # Returns the proper scope object subclass based
      # on the definition
      #
      # @param  name [Symbol] The name of the scope
      # @param  definition [Hash] Hash detailing the arguments
      # needed for the scope
      #
      # @raise [InvalidDefinition] Error that occurs when the definition
      # of a scope is invalid
      #
      # @return [AbstractScope] A subclass of AbstractScope
      def self.factory(name, definition)
        arg_types = definition.values

        if arg_types.include?(:rest)
          # Check if the definition has a :rest
          return VariableArgScope.new(name, definition)
        elsif arg_types.include?(:opt)
          # Check if the definition has optional arguments
          return OptionalArgScope.new(name, definition)
        else
          # Otherwise instantiate the default class
          return DefaultScope.new(name, definition)
        end

      end

      def initialize(name, definition)
      end

    end

  end

end