require 'api_resource/associations/resource_scope'

module ApiResource
  module Associations

    class GenericScope < ResourceScope
      attr_reader :name
      attr_reader :params
      attr_reader :types
      attr_reader :values

      # Gets called when a scope is called.  Stores everything in
      # this class.  Sorry, couldn't be bothered to figure out the 
      # class hierarchy.
      #
      # klass - ApiResourceBase class
      # current_scope - sym for the scope
      # *args - arguments being passed to the scope
      def initialize(klass, current_scope, *args)

        @name = current_scope # contains sym with scope ie :for_provider
        @params = klass.related_objects[:scopes][current_scope].keys
        @types = klass.related_objects[:scopes][current_scope].values

        # Bail if we have crap
        if @params == nil
          raise "Scope #{@name} does not exist #{klass.name}.  Scopes: #{klass.related_objects[:scopes]}" 
        end

        # extract parent scope stuff
        opts = {}
        last_arg = args[args.count - 1]
        if last_arg != nil && last_arg.is_a?(Hash) && last_arg[:parent] != nil
          args = args.slice(0, args.count - 1)
          opts = last_arg
        end

        # walk through parameters and types and assign values from *args to parameters
        @values = []
        @params.count.times do |i|
          if @types[i] == :rest
            @values << args.slice(i, args.count)
          else
            @values << args[i]
          end
        end

        # Let the parent class do its magic.
        super(klass, current_scope, opts)
      end

      # get the to_query value for this resource scope
      def to_hash
        # debugger
        if @params.count == 0
          scope_arguments = true 
        else 
          scope_arguments = {}
          @params.count.times do |i|
            scope_arguments[@params[i]] = @values[i] if @values[i] != nil
          end
        end
        self.parent_hash.merge({@name => scope_arguments})
      end
    end
  end
end

