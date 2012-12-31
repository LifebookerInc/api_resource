module ApiResource
  module Associations
    class HasOneRemoteObjectProxy < SingleObjectProxy
      
      def initialize(klass, owner)
        super(klass, owner)
        
        # now if we have an owner and a foreign key, we set the data up to load
        self.remote_path = self.klass.collection_path(self.owner.class.to_s.foreign_key => self.owner.id)
      end

      protected

      # because of how this works we use a multi object proxy and return the first element
      def to_condition
        ApiResource::Conditions::MultiObjectAssociationCondition.new(self.klass, self.remote_path)
      end
      
      def load(opts = {})
        @loaded = true
        Array.wrap(self.to_condition.find).first
      end

    end
  end
end