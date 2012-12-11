require 'api_resource/associations/single_object_proxy'
module ApiResource
  module Associations
    class BelongsToRemoteObjectProxy < SingleObjectProxy
      def initialize(klass, owner)
        super(klass, owner)
        
        # now if we have an owner and a foreign key, we set the data up to load
        if key = owner.send(self.klass.to_s.foreign_key)
          self.remote_path =  self.klass.element_path(key)
        end
      end
    end
  end
end