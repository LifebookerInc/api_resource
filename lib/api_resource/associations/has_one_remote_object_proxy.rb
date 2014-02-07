module ApiResource
  module Associations
    class HasOneRemoteObjectProxy < SingleObjectProxy

      # defines a method to get the id of the associated objecgt
      # def self.define_association_as_attribute(klass, assoc_name, opts = {})
      #   id_method_name = self.foreign_key_name(assoc_name)

      #   klass.api_resource_generated_methods.module_eval <<-EOE, __FILE__, __LINE__ + 1
      #     def #{id_method_name}
      #       self.#{assoc_name}? ? self.#{assoc_name}.id : nil
      #     end
      #   EOE
      #   super
      # end

      # def internal_object
      #   # if we don't have a remote path and we do have and id,
      #   # we set it before we call the internal object
      #   # this lets us dynamically generate the correct path
      #   if self.remote_path.blank? && self.owner.try(:id).present?
      #     self.remote_path = self.klass.collection_path(
      #       self.owner.class.to_s.foreign_key => self.owner.id
      #     )
      #   end
      #   super
      # end

      # protected

      # # because of how this works we use a multi object proxy and return the first element
      # def to_condition
      #   ApiResource::Conditions::SingleObjectAssociationCondition.new(
      #     self.klass, self.remote_path
      #   )
      # end
    end
  end
end