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
        return ApiResource::Associations::HasOneProxy.new(
          object,
          self
        )
      end


    end

  end

end