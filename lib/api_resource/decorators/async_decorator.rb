module ApiResource

  module Decorators

    #
    # Wrapper class for deferring loads into a celluloid
    # future to happen in another thread
    #
    # @author [ejlangev]
    #
    class AsyncDecorator
      # @!attribute [r] future
      # @return [Celluloid::Future] The future that handles
      # making the blocking calls to load
      attr_reader :future

      #
      # @param  finder [ApiResource::Finders::AbstractFinder] Some kind of
      # finder object that needs to be loaded
      # @param  &block [Block] Optional block to execute on the result of the
      # load
      def initialize(finder, &block)
        @future = Celluloid::Future.new do
          # Load the value from the finder by calling internal
          # object to actually load the data
          results = finder.internal_object
          # Now yield result to the block if it is given
          block_given? ? yield(results) : results
        end
      end

      #
      # Blocks on the result of the future, takes a block to execute
      # on the results of the future
      #
      # @param  &block [Block] Optional block to execute on the results
      #
      # @return [Object]
      def value(&block)
        block_given? ? yield(@future.value) : @future.value
      end

      #
      # Proxies all missing methods to the result of the future
      #
      # @param  sym [Symbol] Method name to call
      # @param  *args [Array<Object>] Arguments to pass
      # @param  &block [Block] A block if it is given
      #
      # @return [Object] The result of calling the method sym
      # on the result of the future
      def method_missing(sym, *args, &block)
        self.value.__send__(sym, *args, &block)
      end

    end

  end

end