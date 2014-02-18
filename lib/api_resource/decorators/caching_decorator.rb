module ApiResource
  module Decorators
    class CachingDecorator

      # @!attribute [r] owner
      # @return [Object] Either a condition object or an
      # association proxy object
      attr_reader :owner

      # @!attribute [r] ttl
      # @return [Integer] The time to cache this result for
      # in seconds
      attr_reader :ttl

      #
      # @param  owner [Object] Either a condition or some
      # type of association object
      #
      # @param  ttl [Integer] The time to cache the result for
      def initialize(owner, ttl)
        @owner = owner
        @ttl = ttl
      end

      #
      # Proxies unknown methods down to the owner object
      # but wrapped in a cache block so that the load call will
      # be cached
      #
      # @param  method_name [Symbol]
      # @param  *args [Array<Object>]
      # @param  &block [Block]
      #
      # @return [Object]
      def method_missing(method_name, *args, &block)
        ApiResource.with_ttl(self.ttl) do
          self.owner.send(method_name, *args, &block)
        end
      end
    end
  end
end
