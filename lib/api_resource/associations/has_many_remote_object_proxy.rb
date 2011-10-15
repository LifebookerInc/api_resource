require 'api_resource/associations/multi_object_proxy'
module ApiResource
  module Associations
    class HasManyRemoteObjectProxy < MultiObjectProxy
      def initialize(klass_name, contents, owner)
        super
        return if self.internal_object.present? || self.remote_path
        # now if we have an owner and a foreign key, we set the data up to load
        if owner
          self.load({"service_uri" => self.klass.collection_path(self.owner.class.to_s.foreign_key => self.owner.id)}.merge(self.klass.scopes))
        end
        true
      end
    end
  end
end