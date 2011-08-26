require 'active_support'
require 'active_support/string_inquirer'

module ApiResource
  
  module Associations
    extend ActiveSupport::Concern
    
    ASSOCIATION_TYPES = [:belongs_to, :has_one, :has_many]
    
    included do
      # Define a class inheritable accessor for keeping track of the associations
      # when this module is included
      class_inheritable_accessor :related_objects
    
      # Hash to hold onto the definitions of the related objects
      self.related_objects = {
        :belongs_to => {}.with_indifferent_access,
        :has_one => {}.with_indifferent_access,
        :has_many => {}.with_indifferent_access,
        :scope => {}.with_indifferent_access
      }.with_indifferent_access
      
    end

    module ClassMethods
      
      # Define the methods for creating and testing for associations, unfortunately
      # scopes are different enough to require different methods :(
      ApiResource::Associations::ASSOCIATION_TYPES.each do |assoc|
        self.module_eval <<-EOE, __FILE__, __LINE__ + 1
          def #{assoc}(*args)
            options = args.extract_options!
            # Raise an error if we have multiple args and options
            raise "Invalid arguments to #{assoc}" unless options.blank? || args.length == 1
            args.each do |arg|
              self.related_objects[:#{assoc}][arg.to_sym] = (options[:class_name] ? options[:class_name].to_s.classify : arg.to_s.classify)
              # We need to define reader and writer methods here
              define_association_as_attribute(:#{assoc}, arg)
            end
          end
          
          def #{assoc}?(name)
            return self.related_objects[:#{assoc}][name.to_s.pluralize.to_sym].present? || self.related_objects[:#{assoc}][name.to_s.singularize.to_sym].present?
          end
          
          def #{assoc}_class_name(name)
            raise "No such" + :#{assoc}.to_s + " association on #{name}" unless self.#{assoc}?(name)
            return self.related_objects[:#{assoc}][name.to_sym]
          end            

        EOE
      end
      
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
      
      def association?(assoc)
        self.related_objects.any? do |key, value|
          next if key.to_s == "scope"
          value.detect { |k,v| k.to_sym == assoc.to_sym }
        end
      end
      
      def association_class_name(assoc)
        raise ArgumentError, "#{assoc} is not a valid association of #{self}" unless self.association?(assoc)
        result = self.related_objects.detect do |key,value|
          ret = value.detect{|k,v| k.to_sym == assoc.to_sym }
          return ret[1] if ret
        end
      end
      
      def clear_associations
        self.related_objects.each do |_, val|
          val.clear
        end
      end
      
      protected
      def define_association_as_attribute(assoc_type, assoc_name)
        define_attributes assoc_name
        case assoc_type.to_sym
          when :has_many
            self.class_eval <<-EOE, __FILE__, __LINE__ + 1
              def #{assoc_name}
                self.attributes[:#{assoc_name}] ||= MultiObjectProxy.new(self.class.to_s, nil)
              end
            EOE
          else
            self.class_eval <<-EOE, __FILE__, __LINE__ + 1
              def #{assoc_name}
                self.attributes[:#{assoc_name}] ||= SingleObjectProxy.new(self.class.to_s, nil)
              end
            EOE
        end
        # Always define the setter the same
        self.class_eval <<-EOE, __FILE__, __LINE__ + 1
          def #{assoc_name}=(val)
            #{assoc_name}_will_change! unless self.#{assoc_name}.internal_object == val
            self.#{assoc_name}.internal_object = val
          end
        EOE
      end
      
    end
    
    module InstanceMethods
      # For convenience we will define the methods for testing for the existence of an association
      # and getting the class for an association as instance methods too to avoid tons of self.class calls
      ApiResource::Associations::ASSOCIATION_TYPES.each do |assoc|
        module_eval <<-EOE, __FILE__, __LINE__ + 1
          def #{assoc}?(name)
            return self.class.#{assoc}?(name)
          end
          
          def #{assoc}_class_name(name)
            return self.class.#{assoc}_class_name(name)
          end
        EOE
      end
      
      def association?(assoc)
        self.class.association?(assoc)
      end
      
      def association_class_name(assoc)
        self.class.association_class_name(assoc)
      end
      
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

    class SingleObjectProxy < AssociationProxy

      def serializable_hash(options = {})
        self.internal_object.serializable_hash(options)
      end

      protected
      def load_scope_with_options(scope, options)
        scope = self.loaded_hash_key(scope.to_s, options)
        # If the service uri is blank you can't load
        return nil if self.remote_path.blank?
        unless self.loaded[scope]
          self.times_loaded += 1
          self.loaded[scope] = self.klass.connection.get("#{self.remote_path}.#{self.klass.format.extension}?#{options.to_query}")
        end
        self.klass.new(self.loaded[scope])
      end

      def load(contents)
        # If we get something nil this should just behave like nil
        return if contents.nil?
        raise "Expected an attributes hash got #{contents}" unless contents.is_a?(Hash)
        # If we don't have a 'service_uri' just assume that these are all attributes and make an object
        return @internal_object = self.klass.new(contents) unless contents[self.class.remote_path_element]
        # allow for symbols vs strings with these elements
        self.remote_path = contents.delete(self.class.remote_path_element) || contents.delete(self.class.remote_path_element.to_s)
        # There's only one hash here so it's hard to distinguish attributes from scopes, the key scopes_only says everything
        # in this hash is a scope
        no_attrs = (contents.delete("scopes_only") || contents.delete(:scopes_only) || false)
        attrs = {}
        contents.each do |key, val|
          # if this key is an attribute add it to attrs, warn if we've set scopes_only
          if self.klass.attribute_names.include?(key) && !no_attrs
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

    class MultiObjectProxy < AssociationProxy

      include Enumerable

      def all
        self.internal_object
      end

      def each(*args, &block)
        self.internal_object.each(*args, &block)
      end

      def serializable_hash(options)
        self.internal_object.collect{|obj| obj.serializable_hash(options) }
      end

      # force a load when calling this method
      def internal_object
        @internal_object ||= self.load_scope_with_options(:all, {})
      end

      protected
      def load_scope_with_options(scope, options)
        scope = self.loaded_hash_key(scope.to_s, options)
        return [] if self.remote_path.blank?
        unless self.loaded[scope]
          self.times_loaded += 1
          self.loaded[scope] = self.klass.connection.get("#{self.remote_path}.#{self.klass.format.extension}?#{options.to_query}")
        end
        self.loaded[scope].collect{|item| self.klass.new(item)}
      end

      def load(contents)
        # If we have a blank array or it's just nil then we should just return after setting internal_object to a blank array
        @internal_object = [] and return nil if (contents.is_a?(Array) && contents.blank?) || contents.nil?
        if contents.is_a?(Array) && contents.first.is_a?(Hash) && contents.first[self.class.remote_path_element]
          settings = contents.slice!(0).with_indifferent_access
        end

        settings = contents if contents.is_a?(Hash)
        settings ||= {}.with_indifferent_access

        raise "Invalid response for multi object relationship: #{contents}" unless settings[self.class.remote_path_element] || contents.is_a?(Array)
        self.remote_path = settings.delete(self.class.remote_path_element)

        settings.each do |key, value|
          raise "Expected the scope #{key} to point to a hash, to #{value}" unless value.is_a?(Hash)
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{key}(opts = {})
              ApiResource::Associations::RelationScope.new(self, :#{key}, opts)
            end
          EOE
          self.scopes[key.to_s] = value
        end

        # Create the internal object
        @internal_object = contents.is_a?(Array) ? contents.collect{|item| self.klass.new(item)} : nil
      end
    end
  end
  
end
