require 'api_resource/associations/single_object_proxy'
module ApiResource
  module Associations
    class HasOneRemoteObjectProxy < SingleObjectProxy
      def initialize(klass_name, contents, owner)
        super
        return if self.internal_object
        # now if we have an owner and a foreign key, we set the data up to load
        if owner
          self.load({"service_uri" => self.klass.collection_path(self.owner.class.to_s.foreign_key => self.owner.id)}.merge(self.klass.scopes))
        end
        true
      end
    end
  end
end