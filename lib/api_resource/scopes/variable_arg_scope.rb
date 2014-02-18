module ApiResource

  module Scopes

    #
    # Scope class to represent taking a variable number of
    # arguments
    #
    # @author [ejlangev]
    #
    class VariableArgScope < AbstractScope

      # @!attribute required_arg_names
      # @return [Array<Symbol>] The names of the required args
      attr_reader :required_arg_names

      # @!attribute rest_arg_name
      # @return [Symbol] The name of the rest of the arguments
      attr_reader :rest_arg_name

      #
      # @param  name [Symbol] The name of the scope
      # @param  definition [Hash] Map from symbol arg names to symbol
      # arg types
      def initialize(name, definition)
        arg_names = definition.keys
        arg_types = definition.values

        unless self.valid_arg_types?(arg_types)
          raise InvalidDefinition.new(
            "Invalid definition #{definition} for a VariableArgScope"
          )
        end

        @required_arg_names = arg_names[0..-2]
        @rest_arg_name = arg_names.last

        super(name, arg_names, arg_types)
      end

      #
      # Apply this scope to the provided args based on the provided
      # class
      #
      # @param  klass [Class] The class to base the conditions on
      # @param  *args [Array<Object>] List of args to apply
      #
      # @return [ApiResource::Conditions::ScopeCondition]
      def apply(klass, *args)
        if args.length < self.required_arg_names.length
          raise InvalidArgument.new(
            "Need to call #{self.name} with at least " +
            "#{self.required_arg_names.length} arguments"
          )
        end
        # First deal with the required arguments
        final_args = self.required_arg_names.zip(args).take(
          self.required_arg_names.length
        )
        # Then push everything else into the variable arg
        final_args.push([
          self.rest_arg_name,
          args.drop(self.required_arg_names.length)
        ])
        # Then build the condition object
        condition_arg = {
          self.name => Hash[final_args]
        }

        return ApiResource::Conditions::WhereCondition.new(
          klass,
          condition_arg
        )
      end

      protected

        #
        # Make sure these argument types are valid
        #
        # @param  arg_types [Array<Symbol>] List of the provided arg types
        #
        # @return [Boolean] True if valid, false otherwise
        def valid_arg_types?(arg_types)
          # Make sure we have a :rest arg type
          arg_types.last == :rest &&
          # Make sure we don't have any :opt arg types
          arg_types.none? { |at| at == :opt } &&
          # Make sure the only occurrence of :rest is in the last position
          arg_types.index(:rest) == arg_types.length - 1
        end

    end

  end

end