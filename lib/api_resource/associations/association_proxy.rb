module ApiResource
  
  module Associations
   
    class AssociationProxy

      cattr_accessor :remote_path_element; self.remote_path_element = :service_uri
      cattr_accessor :include_class_scopes; self.include_class_scopes = true

      attr_accessor :loaded, :klass, :internal_object, :remote_path, :scopes, :times_loaded

      def initialize(klass_name, contents)
        raise "Cannot create an association proxy to the unknown object #{klass_name}" unless defined?(klass_name.to_s.classify)
        # A simple attr_accessor for testing purposes
        self.times_loaded = 0
        self.klass = klass_name.to_s.classify.constantize
        self.load(contents)
        self.loaded = {}.with_indifferent_access
        if self.class.include_class_scopes
          self.scopes = self.scopes.reverse_merge(self.klass.scopes)
        end
        # Now that we have set up all the scopes with the load method we need to create methods
        self.scopes.each do |key, _|
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{key}(opts = {})
              ApiResource::Associations::RelationScope.new(self, :#{key}, opts)
            end
          EOE
        end
      end
      
      def serializable_hash(options = {})
        raise "Not Implemented: This method must be implemented in a subclass"
      end

      def scopes
        @scopes ||= {}.with_indifferent_access
      end

      def scope?(scp)
        self.scopes.keys.include?(scp.to_s)
      end

      def internal_object
        @internal_object ||= self.load_scope_with_options(:all, {})
      end
      
      def blank?
        self.internal_object.blank?
      end
      alias_method :empty?, :blank?

      def method_missing(method, *args, &block)
        self.internal_object.send(method, *args, &block)
      end

      def reload(scope =  nil, opts = {})
        if scope.nil?
          self.loaded.clear
          self.times_loaded = 0
          # Remove the loaded object to force it to reload
          remove_instance_variable(:@internal_object)
        else
          # Delete this key from the loaded hash which will cause it to be reloaded
          self.loaded.delete(self.loaded_hash_key(scope, opts))
        end
        self
      end
      
      def to_s
        self.internal_object.to_s
      end
      
      def inspect
        self.internal_object.inspect
      end

      protected
      # This method loads a particular scope with a set of options from the remote server
      def load_scope_with_options(scope, options)
        raise "Not Implemented: This method must be implemented in a subclass"
      end
      # This method is a helper to initialize for loading the data passed in to create this object
      def load(contents)
        raise "Not Implemented: This method must be implemented in a subclass"
      end

      # This method create the key for the loaded hash, it ensures that a unique set of scopes
      # with a unique set of options is only loaded once
      def loaded_hash_key(scope, options)
        options.to_a.sort.inject(scope) {|accum,(k,v)| accum << "_#{k}_#{v}"}
      end
    end
    
  end
  
end