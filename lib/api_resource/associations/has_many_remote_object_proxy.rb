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
        if self.remote_path.blank?
          # first try for a set of ids e.g. /objects.json?ids[]=1
          associated_ids = self.owner.read_attribute(
            self.association_id_method
          )
          if associated_ids.is_a?(Array) && associated_ids.present?
            self.remote_path = self.klass.collection_path(
              :ids => associated_ids
            )
          # next try for a foreign key e.g. /objects.json?owner_id=1
          elsif self.owner.try(:id).present?
            self.remote_path = self.klass.collection_path(
              self.owner.class.to_s.foreign_key => self.owner.id
            )
          end
        end
        super
      end

      protected

      # The method by which we get ids for the association
      # e.g. object_ids
      def association_id_method
        self.class.foreign_key_name(@options["name"])
      end


    end
  end
end
