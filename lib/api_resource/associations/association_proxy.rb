module ApiResource
  
  module Associations
   
    class AssociationProxy
      
      
      cattr_accessor :remote_path_element; self.remote_path_element = :service_uri
      cattr_accessor :include_class_scopes; self.include_class_scopes = true

      attr_accessor :owner, :loaded, :klass, :internal_object, :remote_path, :scopes, :times_loaded

      # TODO: added owner - moved it to the end because the tests don't use it - it's useful here though
      def initialize(klass_name, contents, owner = nil)
        raise "Cannot create an association proxy to the unknown object #{klass_name}" unless defined?(klass_name.to_s.classify)
        # A simple attr_accessor for testing purposes
        self.times_loaded = 0
        self.owner = owner
        self.klass = klass_name.to_s.classify.constantize
        self.load(contents)
        self.loaded = {}.with_indifferent_access
        if self.class.include_class_scopes
          self.scopes = self.scopes.reverse_merge(self.klass.scopes)
        end
        # Now that we have set up all the scopes with the load method we need to create methods
        self.scopes.each do |key, _|
          next if self.respond_to?(key)
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{key}(opts = {})
              @#{key} ||= ApiResource::Associations::RelationScope.new(self, :#{key}, opts)
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
      
      def ==(other)
         raise "Not Implemented: This method must be implemented in a subclass"
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
      
      # get the remote URI based on our config and options
      def build_load_path(options)
        path = self.remote_path
        # add a format if it doesn't exist and there is no query string yet
        path += ".#{self.klass.format.extension}" unless path =~ /\./ || path =~/\?/
        # add the query string, allowing for other user-provided options in the remote_path if we have options
        unless options.blank?
          path += (path =~ /\?/ ? "&" : "?") + options.to_query 
        end
        path
      end

      # get data from the remote server
      def load_from_remote(options)
        self.klass.connection.get(self.build_load_path(options))
      end
      # This method create the key for the loaded hash, it ensures that a unique set of scopes
      # with a unique set of options is only loaded once
      def loaded_hash_key(scope, options)
        options.to_a.sort.inject(scope) {|accum,(k,v)| accum << "_#{k}_#{v}"}
      end
    end
    
  end
  
end