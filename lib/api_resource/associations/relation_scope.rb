require 'api_resource/associations/scope'

module ApiResource
  
  module Associations
    
    class RelationScope < Scope

      def reload
        remove_instance_variable(:@internal_object) if instance_variable_defined?(:@internal_object)
        self.klass.reload(self.current_scope, self.scopes[self.current_scope])
        self
      end

      # Use this method to access the internal data, this guarantees that loading only occurs once per object
      def internal_object
        @internal_object ||= self.klass.send(:load_scope_with_options, self.current_scope, self.scopes[self.current_scope])
      end

    end
    
  end
  
end