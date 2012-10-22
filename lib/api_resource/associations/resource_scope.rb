require 'api_resource/associations/scope'

module ApiResource

  module Associations

    class ResourceScope < Scope

      include Enumerable

      def internal_object
        ApiResource.with_ttl(ttl) do
          @internal_object ||= self.klass.send(:find, :all, :params => self.to_hash)
        end
      end

      alias_method :all, :internal_object

      def each(*args, &block)
        self.internal_object.each(*args, &block)
      end

      # Used by ApiResource::Scopes to create methods with the same name
      # as the scope
      #
      # Weird place to have a factory... could have been on Scope or a separate class...
      def self.class_factory(hsh)
        return ApiResource::Associations::GenericScope
      end
    end
  end
end
