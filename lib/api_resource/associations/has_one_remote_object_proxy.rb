require 'api_resource/associations/single_object_proxy'
module ApiResource
  module Associations
    class HasOneRemoteObjectProxy < SingleObjectProxy
      
      def initialize(klass, owner)
        super(klass, owner)
        
        # now if we have an owner and a foreign key, we set the data up to load
        self.remote_path = self.klass.collection_path(self.owner.class.to_s.foreign_key => self.owner.id)
      end

      protected
      
      def load(opts = {})
        data = self.klass.connection.get(self.build_load_path(opts))
        return nil if data.blank?
        return self.klass.new(data.first)
      end

    end
  end
end