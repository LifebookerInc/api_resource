require 'api_resource/associations/scope'

module ApiResource
  
  module Associations
    
    class ResourceScope < Scope
      
      include Enumerable

      def internal_object
        @internal_object ||= self.klass.send(:find, :all, :params => self.to_hash)
      end
      
      alias_method :all, :internal_object
      
      def each(*args, &block)
        self.internal_object.each(*args, &block)
      end
      
      # get the relevant class
      def self.class_factory(hsh)
        case hsh.values.first
          when TrueClass, FalseClass
            ApiResource::Associations::ResourceScope
          when Array
            ApiResource::Associations::MultiArgumentResourceScope
          else
            ApiResource::Associations::DynamicResourceScope
        end
      end
    end
  end
end