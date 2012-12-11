require 'api_resource/associations/multi_object_proxy'
module ApiResource
  module Associations
    class HasManyRemoteObjectProxy < MultiObjectProxy
      def initialize(klass, owner)
        super(klass, owner)
        self.remote_path = self.klass.collection_path(
          self.owner.class.to_s.foreign_key => self.owner.id
        )
      end
    end
  end
end
