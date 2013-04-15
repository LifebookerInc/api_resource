module ApiResource
  module AssociationActivation
    extend ActiveSupport::Concern
    
    included do
      class_attribute :association_types
      # our default association types
      self.association_types = {
        :belongs_to => :belongs_to_remote, 
        :has_one => :has_one_remote, 
        :has_many => :has_many_remote
      }
    end
    
    module ClassMethods
      def activate_associations(assoc_types = nil)
        self.association_types = assoc_types unless assoc_types.nil?
        self.send(:include, ApiResource::Associations)
      end
    end
    
  end
end