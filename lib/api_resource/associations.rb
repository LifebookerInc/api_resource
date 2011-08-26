require 'active_support'
require 'active_support/string_inquirer'
require 'api_resource/associations/relation_scope'
require 'api_resource/associations/resource_scope'
require 'api_resource/associations/multi_object_proxy'
require 'api_resource/associations/single_object_proxy'

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

  end
  
end