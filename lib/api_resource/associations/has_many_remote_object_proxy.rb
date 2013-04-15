module ApiResource
  module Associations
    class HasManyRemoteObjectProxy < MultiObjectProxy

      # defines a method to get the foreign key
      def self.define_association_as_attribute(klass, assoc_name, opts = {})
        id_method_name = self.foreign_key_name(assoc_name)

        klass.api_resource_generated_methods.module_eval <<-EOE, __FILE__, __LINE__ + 1
          
          def #{id_method_name}
            @attributes_cache[:#{id_method_name}] ||= begin
              # check our attributes first, then go to the remote
              @attributes[:#{id_method_name}] || self.#{assoc_name}.collect(
                &:id
              )
            end
          end
        EOE
        super
      end

      protected
      # gets the foreign key name for a given association
      # e.g. service_ids
      def self.foreign_key_name(assoc_name)
        super(assoc_name).pluralize
      end

      public

      def internal_object
        # if we don't have a remote path and we do have and id,
        # we set it before we call the internal object
        # this lets us dynamically generate the correct path
        if self.remote_path.blank? && self.owner.try(:id).present?
          self.remote_path = self.klass.collection_path(
            self.owner.class.to_s.foreign_key => self.owner.id
          )
        end
        super
      end
    end
  end
end
