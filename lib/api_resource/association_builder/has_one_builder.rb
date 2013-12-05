module ApiResource

  module AssociationBuilder

    class HasOneBuilder < AbstractBuilder

      #
      # Build a single object association proxy with the correct
      # information
      #
      # @param  owner [Object] Object who owns this proxy
      #
      # @return [ApiResource::Associations::SingleObjectProxy]
      def association_proxy(object)
        return ApiResource::Associations::SingleObjectProxy.new(
          self.association_class,
          object
        )
      end


    end

  end

end