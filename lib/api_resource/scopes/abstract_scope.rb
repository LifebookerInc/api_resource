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

      # @!attribute arg_names
      # @return [Array<Symbol>] List of the argument names
      attr_reader :arg_names

      # @!attribute arg_types
      # @return [Array<Symbol>] List of argument types
      attr_reader :arg_types

      # @!attribute name
      # @return [Symbol] The name of this scope
      attr_reader :name

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

      #
      # @param  name [Symbol] The name of the scope
      # @param  arg_names [Array<Symbol>] List of argument names
      # @param  arg_types [Array<Symbol>] List of argument types
      def initialize(name, arg_names, arg_types)
        @name = name
        @arg_names = arg_names
        @arg_types = arg_types
      end

      #
      # Apply this scope to a set of arguments to produce
      # a conditions object
      #
      # @param  klass [Class] The class this is a condition over
      # @param  *args [Array<Object>] The arguments
      #
      # @return [ApiResource::Conditions::ScopeCondition]
      def apply(klass, *args)
        raise NotImplementedError.new(
          'Must implement apply in a subclass of AbstractScope'
        )
      end

    end

  end

end