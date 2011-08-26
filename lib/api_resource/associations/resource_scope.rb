require 'api_resource/associations/scope'

module ApiResource
  
  module Associations
    
    class ResourceScope < Scope
      
      include Enumerable

      def internal_object
        @internal_object ||= self.klass.send(:find, :all, :params => self.scopes[self.current_scope])
      end
      
      alias_method :all, :internal_object
      
      def each(*args, &block)
        self.internal_object.each(*args, &block)
      end

    end
    
  end
  
end