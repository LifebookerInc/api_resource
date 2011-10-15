require 'api_resource/associations/single_object_proxy'
module ApiResource
  module Associations
    class AttrSingleObjectProxy < SingleObjectProxy
      def initialize(klass_name, contents, owner)
        super
        return if self.internal_object
        # now if we have an owner and a foreign key, we set the data up to load
        if owner && key = owner.send(self.klass.to_s.foreign_key)
          self.load({"service_uri" => self.klass.element_path(key), "scopes_only" => true}.merge(self.klass.scopes))
        end
        true
      end
    end
  end
end