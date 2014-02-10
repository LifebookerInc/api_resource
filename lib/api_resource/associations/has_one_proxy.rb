module ApiResource

  module Associations

    #
    # Responsible for managing loading and caching for has one associations
    #
    # @author [ejlangev]
    #
    class HasOneProxy < SingleObjectProxy

      #
      # Proxies to the internal object to read the foreign
      # key.  This forces a load
      #
      # @return [Integer] The foreign key
      def read_foreign_key
        self.internal_object.send(
          :read_attribute,
          :id
        )
      end

      #
      # Sets the foreign key for this association.  This forces a
      # load but does _NOT_ save the associated record afterwards
      #
      # @param  val [Integer] The new foreign key
      #
      # @return [Integer] The new foreign key
      def write_foreign_key(val)
        # Short circuit if everything is loaded and we are assigning
        # to the same value
        if @is_loaded && val == self.read_foreign_key
          return val
        end

        # Otherwise set the internal object to the result of
        # a find call
        @internal_object = self.builder.association_class.find(val)
        @is_loaded = true
        val
      end

    end

  end

end