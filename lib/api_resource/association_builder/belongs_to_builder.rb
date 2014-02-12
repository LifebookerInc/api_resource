module ApiResource

  module AssociationBuilder

    #
    # Responsible for building the necessary objects to manage a
    # belongs to association
    #
    # @author [ejlangev]
    #
    class BelongsToBuilder < AbstractBuilder

      #
      # Build a single object association proxy with the correct
      # information
      #
      # @param  owner [Object] Object who owns this proxy
      #
      # @return [ApiResource::Associations::SingleObjectProxy]
      def association_proxy(owner)
        return ApiResource::Associations::BelongsToProxy.new(
          owner,
          self
        )
      end

      protected

        #
        # Builds the foreign key field name for this association
        #
        # @param  owner_class_name [String]
        # @param  assoc_class_name [String]
        #
        # @return [Symbol] The name of the foreign key
        def construct_foreign_key(owner_class_name, assoc_class_name)
          assoc_class_name.foreign_key.to_sym
        end

    end

  end

end