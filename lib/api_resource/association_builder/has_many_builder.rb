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
        # Creates a pluralized foreign key
        #
        # @param  assoc_name [Symbol] Name of the association
        # @param  assoc_class_name [String] Class name of associated objects
        #
        # @return [Symbol] The foreign key name
        def construct_foreign_key(assoc_name, assoc_class_name)
          assoc_class_name.foreign_key.pluralize.to_sym
        end

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