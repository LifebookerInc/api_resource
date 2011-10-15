require 'api_resource/associations/association_proxy'

module ApiResource
  
  module Associations
    
    class SingleObjectProxy < AssociationProxy

      def serializable_hash(options = {})
        self.internal_object.serializable_hash(options)
      end
      
      def internal_object=(contents)
        return @internal_object = contents if contents.is_a?(self.klass)
        return load(contents)
      end

      protected
      def load_scope_with_options(scope, options)
        scope = self.loaded_hash_key(scope.to_s, options)
        # If the service uri is blank you can't load
        return nil if self.remote_path.blank?
        unless self.loaded[scope]
          self.times_loaded += 1
          path = self.remote_path
          # add a format if it doesn't exist and there is no query string yet
          path += ".#{self.klass.format.extension}" unless path =~ /\./ || path =~/\?/
          # add the query string, allowing for other user-provided options in the remote_path if we have options
          unless options.blank?
            path += (path =~ /\?/ ? "&" : "?") + options.to_query 
          end
          self.loaded[scope] = self.klass.connection.get(path)
        end
        self.klass.new(self.loaded[scope])
      end

      def load(contents)
        # If we get something nil this should just behave like nil
        return if contents.nil?
        raise "Expected an attributes hash got #{contents}" unless contents.is_a?(Hash)
        contents = contents.with_indifferent_access
        # If we don't have a 'service_uri' just assume that these are all attributes and make an object
        return @internal_object = self.klass.new(contents) unless contents[self.class.remote_path_element]
        # allow for symbols vs strings with these elements
        self.remote_path = contents.delete(self.class.remote_path_element)
        # There's only one hash here so it's hard to distinguish attributes from scopes, the key scopes_only says everything
        # in this hash is a scope
        no_attrs = (contents.delete("scopes_only") || false)
        attrs = {}
        contents.each do |key, val|
          # if this key is an attribute add it to attrs, warn if we've set scopes_only
          if self.klass.attribute_names.include?(key.to_sym) && !no_attrs
            attrs[key] = val
          else
            warn("#{key} is an attribute of #{self.klass}, beware of name collisions") if no_attrs && self.klass.attribute_names.include?(key)
            raise "Expected the scope #{key} to have a hash for a value, got #{val}" unless val.is_a?(Hash)
            self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
              def #{key}(opts = {})
                ApiResource::Associations::RelationScope.new(self, :#{key}, opts)
              end
            EOE
            self.scopes[key.to_s] = val
          end
        end
        @internal_object = attrs.present? ? self.klass.new(attrs) : nil
      end
      
    end
    
  end
  
end