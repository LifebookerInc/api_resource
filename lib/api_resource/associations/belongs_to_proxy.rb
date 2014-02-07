module ApiResource

  module Associations

    #
    # Proxy class for dealing with belongs to associations
    #
    # @author [ejlangev]
    #
    class BelongsToProxy < SingleObjectProxy

      #
      # Proxies to the owning object to read
      # the foreign key
      #
      # @return [Integer] The foreign key of this association
      def read_foreign_key
        self.owner.send(
          :read_attribute,
          self.builder.foreign_key
        )
      end

      #
      # Proxies to the owning object to set its foreign key
      #
      # @param  val [Object] The value of the foreign key
      #
      # @return [Integer] The new foreign key value
      def write_foreign_key(val)
        self.owner.send(
          :write_attribute,
          self.builder.foreign_key,
          val
        )
      end

    end

  end

end