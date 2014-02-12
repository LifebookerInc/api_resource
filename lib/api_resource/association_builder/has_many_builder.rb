module ApiResource

  module AssociationBuilder

    class HasManyBuilder < AbstractBuilder

      #
      # Constructs and returns an instance of multi object proxy
      #
      # @param  owner [Object]
      #
      # @return [ApiResource::Associations::MultiObjectProxy]
      def association_proxy(owner)
        ApiResource::Associations::HasManyProxy.new(
          owner,
          self
        )
      end

      protected

        #
        # Builds the name of the foreign key method that will
        # be defined on the owner clas
        #
        # @param  assoc_name [Symbol]
        #
        # @return [Symbol] The name of the foreign key method
        # for the owner class
        def construct_foreign_key_method(assoc_name)
          assoc_name.to_s.singularize.foreign_key.pluralize.to_sym
        end

    end

  end

end