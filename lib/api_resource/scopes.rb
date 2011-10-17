module ApiResource
  module Scopes
    extend ActiveSupport::Concern
    
    
    module ClassMethods
      def scopes
        return self.related_objects[:scope]
      end
      
      def scope(name, hsh)
        raise ArgumentError, "Expecting an attributes hash given #{hsh.inspect}" unless hsh.is_a?(Hash)
        self.related_objects[:scope][name.to_sym] = hsh
        # we also need to define a class method for each scope
        self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
          def #{name}(opts = {})
            return ApiResource::Associations::ResourceScope.new(self, :#{name}, opts)
          end
        EOE
      end
      
      def scope?(name)
        self.related_objects[:scope][name.to_sym].present?
      end
      
      def scope_attributes(name)
        raise "No such scope #{name}" unless self.scope?(name)
        self.related_objects[:scope][name.to_sym]
      end
    end
    module InstanceMethods
      def scopes
        return self.class.scopes
      end
      
      def scope?(name)
        return self.class.scope?(name)
      end
      
      def scope_attributes(name)
        return self.class.scope_attributes(name)
      end
    end
  end
end