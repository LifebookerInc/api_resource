module ApiResource

  module Scopes

    #
    # Scope class to represent a scope that allows optional arguments
    #
    # @author [ejlangev]
    #
    class OptionalArgScope < AbstractScope

      # @!attribute optional_arg_names
      # @return [Array<Symbol>]
      attr_reader :optional_arg_names

      # @!attribute required_arg_names
      # @return [Array<Symbol>]
      attr_reader :required_arg_names

      #
      # @param  name [Symbol] The name of the scope
      # @param  definition [Hash] Map from argument name
      # to argument type
      def initialize(name, definition)
        arg_names = definition.keys
        arg_types = definition.values
        # Validate that the arg_types are right
        unless self.valid_arg_types?(arg_types)
          raise InvalidDefinition.new(
            "Invalid scope definition for an optional arg scope: " +
            "#{definition}"
          )
        end
        # Figure out which args belong where
        @optional_arg_names = definition
                                .select { |k,v| v == :opt }
                                .map(&:first)
        @required_arg_names = definition
                                .select { |k,v| v == :req }
                                .map(&:first)

        super(name, arg_names, arg_types)
      end

      #
      # Applies
      # @param  klass [type] [description]
      # @param  *args [type] [description]
      #
      # @return [type] [description]
      def apply(klass, *args)
        # Make sure we have a valid number of arguments
        if args.length < self.required_arg_names.length ||
           args.length > self.arg_names.length
          raise InvalidArgument.new(
            "Need to call #{self.name} with between " +
            "#{self.required_arg_names.length} and " +
            "#{self.arg_names.length} arguments"
          )
        end
        # Only apply as many arg names as we have arguments
        restricted_arg_names = self.arg_names[0...args.length]

        condition_arg = {
          self.name => Hash[restricted_arg_names.zip(args)]
        }

        return ApiResource::Conditions::ScopeCondition.new(
          klass,
          condition_arg
        )
      end

      protected

        #
        # Makes sure the arg types are valid for an optional
        # arg scope.  They must contain at least one :opt argument
        # at the end and no :rest arguments
        #
        # @param  arg_types [Array<Symbol>] The arg names to validate
        #
        # @return [Boolean] True if valid, false otherwise
        def valid_arg_types?(arg_types)
          # Make sure at least one argument is optional
          arg_types.any? { |t| t == :opt } &&
          # Make sure there are no varargs
          arg_types.none? { |t| t == :rest } &&
          # Make sure all required args come before optional ones
          arg_types[arg_types.index(:opt)..-1].none? { |t| t == :req }
        end

    end

  end

end