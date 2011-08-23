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
              # We don't need to also define methods here because attributes takes care of that at load time
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
    
    class RelationScope
      
      include Enumerable
      
      attr_accessor :association_proxy, :current_scope
      
      attr_reader :scopes, :results
      
      def initialize(proxy, current_scope, opts)
        # Give it something to point to
        @association_proxy = proxy
        # Set up the current scope
        @current_scope = Array.wrap(current_scope.to_s)
        
        # define methods for all the scopes
        proxy.scopes.each do |key,val|
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{key}(opts = {})
              self.enhance_current_scope(:#{key}, opts)
              return self
            end
          EOE
          self.scopes[key.to_s] = val
        end
        # This class needs to know about all the scopes of the proxy for chaining
        self.scopes[@current_scope] = self.scopes[current_scope].merge(opts)
      end

      # Force a load of the current scope and return the results
      def all
        @results = self.association_proxy.load_scope_with_options(@current_scope, self.scopes[@current_scope])
      end
      
      # Iterate over the collection
      def each(&block)
        self.association_proxy.load_scope_with_options(@current_scope, self.scopes[@current_scope]).each
      end
      
      # Helper methods for the scopes
      def scopes
        @scopes ||= {}.with_indifferent_access
      end
      
      def scope?(scp)
        self.scopes.keys.include?(scp.to_s)
      end
      
      def current_scope
        ActiveSupport::StringInquirer.new(@current_scope.join("_and_"))
      end
      
      # Current query string to append to the request
      def query_string
        self.scopes[@current_scope].to_query
      end
      
      def method_missing(method, *args, &block)
        # proxy calls to the results object whatever that may be, calling results forces it to load
        self.association_proxy.load_scope_with_options(@current_scope, self.scopes[@current_scope]).send(method, *args, &block)
      end
      
      # Enhance the current scope of this class with a new scope
      protected
      def enhance_current_scope(scp, opts)
        scp = scp.to_s
        raise "Unknown scope #{scp}" unless self.scope?(scp)
        # We now create a new scope from the other names
        # First we make them unique and sort them so that order doesn't matter
        current_scope_hash = self.scopes[@current_scope]
        @current_scope = @current_scope.concat([scp.to_s]).uniq.sort
        self.scopes[@current_scope] = current_scope_hash.merge(self.scopes[scp].merge(opts.select{|item| self.scopes[scp.to_s].include?(item.to_s)}))
      end
      
    end
    
    # A class for holding onto associated data
    class AssociationProxy
      
      cattr_accessor :remote_path_element
      
      self.remote_path_element ||= :service_uri
      
      class_inheritable_accessor :include_class_scopes
      
      self.include_class_scopes ||= true
      
      attr_accessor :loaded, :klass, :internal_object, :remote_path, :scopes
      
      def initialize(klass_name, contents)
        raise "Cannot create an association proxy to the unknown object #{klass_name}" unless defined?(klass_name.to_s.classify)
        self.klass = klass_name.to_s.classify.constantize
        self.load(contents)
        self.loaded = {}
        self.scopes[:all] = {}
        @current_scope = [:all]
        # When loading identify scopes defined by the class this is a proxy too
        if self.class.include_class_scopes
          self.scopes = self.scopes.reverse_merge(self.klass.scopes)
        end
      end
      
      # Helper methods for the scopes
      def scopes
        @scopes ||= {}.with_indifferent_access
      end
      
      def scope?(scp)
        self.scopes.keys.include?(scp.to_s)
      end
      
      def load(contents)
        raise "Not Implemented: This method must be implemented in a subclass"
      end
      
      def method_missing(method, *args, &block)
        # calling load scope with options will only do the loading one time
        self.load_scope_with_options([:all], {}).send(method, *args, &block)
      end
      
      def load_scope_with_options(scope, options)
        raise "Not implemented: This method must be implemented in a subclass"
      end
      
    end  
  
    class SingleObjectProxy < AssociationProxy
      
      def serializable_hash(options = {})
        self.internal_object.serializable_hash(options)
      end
      
      def load_scope_with_options(scope, options)
        # If there is no service uri raise an error
        raise "Cannot load scopes on an object without a remote path" if self.remote_path.blank?
        unless self.loaded[scope]
          self.loaded[scope] = self.klass.connection.get("#{self.remote_path}.#{self.klass.format.extension}#{options.to_query}")
        end
        @internal_object = self.klass.new(self.loaded[scope])
      end
       
      protected
      def load(contents)
        raise "Expected an attributes hash got #{contents}" unless contents.is_a?(Hash)
        # We need to think of a good way to tell if this is defining scopes or attributes
        return self.internal_object = self.klass.new(contents) unless contents[self.class.remote_path_element]
        # We have a remote path so take anything that is not a known attribute of this class and make that a scope
        self.remote_path = contents.delete(self.class.remote_path_element)
        
        no_attrs = (contents.delete("scopes_only") || contents.delete(:scopes_only) || false)
        attrs = {}
        contents.each do |key,val|
          if self.klass.attribute_names.include?(key.to_sym) && !no_attrs
            attrs[key] = val
          else
            raise "Expected the scope #{key} to point to a hash, got #{val}" unless val.is_a?(Hash)
            self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
              def #{key}(opts = {})
                ApiResource::Associations::RelationScope.new(self, :#{key}, opts)
              end
            EOE
            self.scopes[key.to_s] = val
          end
        end
        
        self.internal_object = self.klass.new(attrs)
      end
        
    
    end
  
    class MultiObjectProxy < AssociationProxy
      
      # Call all to load the objects
      def all
        return self.load_scope_with_options([:all], {})
      end
      
      def each(&block)
        self.load_scope_with_options([:all], {}).each
      end
      
      def serializable_hash(options = {})
        self.internal_object.collect{|obj| obj.serializable_hash(options) }
      end
      
      # This should be a collection
      def load_scope_with_options(scope, options)
        # If there is no service uri raise an error
        raise "Cannot load scopes on an object without a remote path" if self.remote_path.blank?
        unless self.loaded[scope]
          self.loaded[scope] = self.klass.connection.get("#{self.remote_path}.#{self.klass.format.extension}#{options.to_query}")
        end
        @internal_object = self.loaded[scope].collect{|item| self.klass.new(item)}
      end
      
      protected
      def load(contents)
        # we need to handle blank arrays too so account for them
        self.internal_object = [] and return if contents.is_a?(Array) && contents.blank?
        if contents.is_a?(Array) && contents.first.is_a?(Hash) && contents.first[self.class.remote_path_element]
          settings = contents.slice!(0).with_indifferent_access
        end
        
        settings = contents if contents.is_a?(Hash)
        settings ||= {}
        
        raise "Invalid response for multi object relationship: #{contents}" unless (contents.is_a?(Hash) && contents[self.class.remote_path_element].present?) || !settings.blank?
        
        self.remote_path = settings.delete(self.class.remote_path_element)

        settings.each do |key, value|
          raise "Expected the scope #{key} to point to a hash, got #{value}" unless value.is_a?(Hash)
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{key}(opts = {})
              ApiResource::Associations::RelationScope.new(self, :#{key}, opts)
            end
          EOE
          self.scopes[key.to_s] = value
        end
        
        # Lastly create object for anything passed back from the server
        self.internal_object = contents.is_a?(Array) ? contents.collect{|item| self.klass.new(item)} : []
      end
    end
  end
  
end
