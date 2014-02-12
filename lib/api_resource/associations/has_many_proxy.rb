module ApiResource

  module Associations

    class HasManyProxy < MultiObjectProxy

      def assign(vals)
      end

      def read_foreign_key
        result = self.owner.send(
          :read_attribute,
          self.builder.foreign_key
        )

        return result unless result.nil?
        # If that is nil then try to collect the ids after doing a load
        load unless @is_loaded
        self.internal_object.map(&:id)
      end

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