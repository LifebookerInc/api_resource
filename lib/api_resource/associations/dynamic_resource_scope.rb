require 'api_resource/associations/resource_scope'

module ApiResource
  module Associations
    class DynamicResourceScope < ResourceScope
      
      attr_accessor :dynamic_value
      # initializer - set up the dynamic value
      def initialize(klass, current_scope, dynamic_value, opts = {})
        self.dynamic_value = dynamic_value
        super(klass, current_scope, opts)
      end
      # get the to_query value for this resource scope
      def to_hash
        hsh = self.scopes[self.current_scope].clone
        hsh.each_pair do |k,v|
          hsh[k] = self.dynamic_value
        end
        self.parent_hash.merge(hsh)
      end
    end
  end
end