require 'api_resource/associations/scope'

module ApiResource
  
  module Associations
    
    class RelationScope < Scope

      # Use this method to access the internal data, this guarantees that loading only occurs once per object
      def internal_object
        @internal_object ||= self.klass.send(:load_scope_with_options, self.current_scope, self.to_hash)
      end
      # 
      # class factory
      def self.class_factory(hsh)
        ApiResource::Associations::RelationScope
      end

    end
    
  end
  
end