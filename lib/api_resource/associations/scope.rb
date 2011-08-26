module ApiResource
  
  module Associations
    
    class Scope

      attr_accessor :klass, :current_scope, :internal_object

      attr_reader :scopes

      def initialize(klass, current_scope, opts)
        # Holds onto the association proxy this RelationScope is bound to
        @klass = klass
        @current_scope = Array.wrap(current_scope.to_s)
        # define methods for the scopes of the object

        klass.scopes.each do |key, val|
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            # This class always has at least one scope, adding a new one should clone this object
            def #{key}(opts = {})
              obj = self.clone
              # Call reload to make it go back to the webserver the next time it loads
              obj.reload
              obj.enhance_current_scope(:#{key}, opts)
              return obj
            end
          EOE
          self.scopes[key.to_s] = val
        end
        # Use the method current scope because it gives a string
        # This expression substitutes the options from opts into the default attributes of the scope, it will only copy keys that exist in the original
        self.scopes[self.current_scope] = opts.inject(self.scopes[current_scope]){|accum,(k,v)| accum.key?(k.to_s) ? accum.merge(k.to_s => v) : accum}
      end

      # Use this method to access the internal data, this guarantees that loading only occurs once per object
      def internal_object
        raise "Not Implemented: This method must be implemented in a subclass"
      end

      def scopes
        @scopes ||= {}.with_indifferent_access
      end

      def scope?(scp)
        self.scopes.key?(scp.to_s)
      end

      def current_scope
        ActiveSupport::StringInquirer.new(@current_scope.join("_and_").concat("_scope"))
      end

      def to_query
        self.scopes[self.current_scope].to_query
      end

      def method_missing(method, *args, &block)
        self.internal_object.send(method, *args, &block)
      end

      def reload
        remove_instance_variable(:@internal_object) if instance_variable_defined?(:@internal_object)
        self
      end

      def to_s
        self.internal_object.to_s
      end
      
      def inspect
        self.internal_object.inspect
      end

      protected
        def enhance_current_scope(scp, opts)
          scp = scp.to_s
          raise ArgumentError, "Unknown scope #{scp}" unless self.scope?(scp)
          # Hold onto the attributes related to the old scope that we're going to chain to
          current_scope_hash = self.scopes[self.current_scope]
          # This sets the new current scope making them unique and sorted to make it order independent
          @current_scope = @current_scope.concat([scp.to_s]).uniq.sort
          # This sets up the new options for the current scope, it merges the defaults for the new scope then substitutes from opts
          self.scopes[self.current_scope] = opts.inject(current_scope_hash.merge(self.scopes[scp.to_s])){|accum,(k,v)| accum.key?(k.to_s) ? accum.merge(k.to_s => v) : accum }
        end
    end
    
  end
  
end