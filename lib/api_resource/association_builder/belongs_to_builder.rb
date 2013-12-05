module ApiResource

  module AssociationBuilder

    class BelongsToBuilder < AbstractBuilder

      #
      # Build a single object association proxy with the correct
      # information
      #
      # @param  owner [Object] Object who owns this proxy
      #
      # @return [ApiResource::Associations::SingleObjectProxy]
      def association_proxy(owner)
        return ApiResource::Associations::SingleObjectProxy.new(
          self.association_class,
          owner
        )
      end

    end

  end

end