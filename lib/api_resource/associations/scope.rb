module ApiResource
  module Associations
    class Scope < AbstractScope

      include Enumerable
      
      def initialize(klass, opts = {})
        # see if we have a hash of options and it has a parent in it
        unless opts[:__parent].respond_to?(:load)
          raise ArgumentError.new(
            "Scopes must have a parent object passed in that " + 
            "responds to #load"
          )
        end
        super(klass, opts)
      end

      def each(*args, &block)
        self.internal_object.each(*args, &block)
      end

      def load
        ret = self.klass.load(self.to_hash)
        @loaded = true
        ret
      end

      # we break this out here because Scope needs to pass self.klass to 
      # any sub-scopes.  This is because Scope does not have knowledge
      # of how to actually load data and delegates that to either
      # a ResourceScope or an AssociationScope
      def get_subscope_instance(finder_opts)
        ApiResource::Associations::Scope.new(
          self.klass, finder_opts.merge(:__parent => self)
        )
      end

    end
  end
end