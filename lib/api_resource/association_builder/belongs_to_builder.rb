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

    end

  end

end