module ApiResource

  module Scopes

    #
    # Class to represent a scope that has only required parameters
    #
    # @author [ejlangev]
    #
    class DefaultScope < AbstractScope

      #
      # @param  name [Symbol] Name of the scope
      # @param  definition [Hash] Map from symbol argument name
      # to symbol argument type
      #
      # @raise [ApiResource::Scopes::InvalidDefinition]
      def initialize(name, definition)
        arg_names = definition.keys
        arg_types = definition.values
        # Check to make sure that all of the arg names
        # are :req, otherwise it's a definition error
        unless arg_types.all? { |at| at == :req }
          raise InvalidDefinition.new(
            'Tried to define a default scope with something other than ' +
            'specified parameters'
          )
        end
        # Call the superclass to set attributes
        super(name, arg_names, arg_types)
      end

      #
      # Applies this scope to a given set of arguments
      #
      # @param  klass [Class] The class the condition exists over
      # @param  *args [Array<Object>] The arguments to apply
      #
      # @raise [ApiResource::Scopes::InvalidArgument] When the arity is wrong
      #
      # @return [ApiResource::Conditions::AbstractCondition] Returns the
      # proper type of condition object from this scope
      def apply(klass, *args)
        # Just need to check the arity here because everything is required
        if args.length != self.arg_names.length
          raise InvalidArgument.new(
            "Tried to call a #{self.arg_names.length} argument scope with " +
            "#{args.length} arguments"
          )
        end

        # Build the proper hash to pass into the condition object
        condition_arg = {
          self.name => Hash[self.arg_names.zip(args)]
        }

        return ApiResource::Conditions::ScopeCondition.new(
          klass,
          condition_arg
        )
      end

    end

  end

end