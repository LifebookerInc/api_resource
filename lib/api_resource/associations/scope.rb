module ApiResource
  
  module Associations
    
    class Scope

      attr_accessor :klass, :current_scope, :internal_object

      attr_reader :scopes

      def initialize(klass, current_scope, opts = {})
        # Holds onto the association proxy this RelationScope is bound to
        @klass = klass
        @parent = opts.delete(:parent)
        @ttl = opts.delete(:expires_in)
        # splits on _and_ and sorts to get a consistent scope key order
        @current_scope = (self.parent_scope + Array.wrap(current_scope.to_s)).sort
        # define methods for the scopes of the object

        klass.scopes.each do |key, val|
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            # This class always has at least one scope, adding a new one should clone this object
            def #{key}(*args)
              obj = self.clone
              # Call reload to make it go back to the webserver the next time it loads
              obj.reload
              return obj.enhance_current_scope(:#{key}, *args)
            end
          EOE
          self.scopes[key.to_s] = val
        end
        # Use the method current scope because it gives a string
        # This expression substitutes the options from opts into the default attributes of the scope, it will only copy keys that exist in the original
        self.scopes[self.current_scope] = opts.inject(self.scopes[current_scope]){|accum,(k,v)| accum.key?(k.to_s) ? accum.merge(k.to_s => v) : accum}
      end
      
      def ttl
        @ttl || 0
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

      def to_hash
        self.parent_hash.merge(self.scopes[self.current_scope])
      end
      
      # gets the current hash and calls to_query on it
      def to_query
        #We need to add the unescape because to_query breaks on nested arrays
        CGI.unescape(self.to_hash.to_query)
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
      
      def blank?
        self.internal_object.blank?
      end
      alias_method :empty?, :blank?

      protected
        # scope from the parent
        def parent_scope
          ret = @parent ? Array.wrap(@parent.current_scope).collect{|el| el.gsub(/_scope$/,'')} : []
          ret.collect{|el| el.split(/_and_/)}.flatten
        end
        # querystring hash from parent
        def parent_hash
          @parent ? @parent.to_hash : {}
        end
        def enhance_current_scope(scp, *args)
          opts = args.extract_options!
          check_scope(scp)
          cache_key = "a#{Digest::MD5.hexdigest((args.sort + [scp]).to_s)}"
          return instance_variable_get("@#{cache_key}") if instance_variable_defined?("@#{cache_key}")
          return instance_variable_set("@#{cache_key}", self.class.class_factory(self.scopes[scp]).new(self.klass, scp, *args, opts.merge(:parent => self)))
        end
        # make sure we have a valid scope
        def check_scope(scp)
          raise ArgumentError, "Unknown scope #{scp}" unless self.scope?(scp.to_s)
        end
    end
    
  end
  
end