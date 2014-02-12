module ApiResource

  module Associations

    class HasManyProxy < MultiObjectProxy

      #
      # Reads the foreign keys for this association by first checking
      # if they are set on the owner object and if not then constructing
      # them by loading the associated data
      #
      # @return [Array<Integer>] The foreign keys
      def read_foreign_key
        result = self.owner.send(
          :read_attribute,
          self.builder.foreign_key_method
        )

        return result unless result.nil?
        # If that is nil then try to collect the ids after doing a load
        load unless @is_loaded
        self.internal_object.map(&:id)
      end

      #
      # Sets the foreign key for this association by loading the proper
      # objects and setting their foreign key.  Does _NOT_ call save
      # on those objects.
      #
      # @param  vals [Array<Integer>] List of new id values for the
      # foreign keys
      #
      # @return [Array<Integer>] The new foreign keys
      def write_foreign_key(vals)
        @internal_object = Array.wrap(
          self.builder.association_class.find(
            *vals
          )
        )

        @is_loaded = true
        @internal_object.each do |result|
          result.send(
            :write_attribute,
            self.builder.foreign_key,
            self.owner.read_attribute(:id)
          )
        end

        vals
      end

    end

  end

end