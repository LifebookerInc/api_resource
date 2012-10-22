module ApiResource
  module Decorators
    class CachingDecorator
      attr_reader :owner
      attr_reader :ttl

      def initialize(owner, ttl)
        @owner = owner
        @ttl = ttl
      end


      def method_missing(method_name, *args, &block)
        ApiResource.with_ttl(self.ttl) do
          self.owner.send(method_name, *args, &block)
        end
      end
    end
  end
end
