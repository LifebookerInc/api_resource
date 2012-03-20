require 'active_support'
require 'active_support/string_inquirer'
require 'api_resource/association_activation'
require 'api_resource/associations/relation_scope'
require 'api_resource/associations/resource_scope'
require 'api_resource/associations/dynamic_resource_scope'
require 'api_resource/associations/multi_argument_resource_scope'
require 'api_resource/associations/multi_object_proxy'
require 'api_resource/associations/single_object_proxy'
require 'api_resource/associations/belongs_to_remote_object_proxy'
require 'api_resource/associations/has_one_remote_object_proxy'
require 'api_resource/associations/has_many_remote_object_proxy'
require 'api_resource/associations/related_object_hash'

module ApiResource
  
  module Associations
    extend ActiveSupport::Concern

    included do
      
      raise "Cannot include Associations without first including AssociationActivation" unless self.ancestors.include?(ApiResource::AssociationActivation)
      class_attribute :related_objects
            
      # Hash to hold onto the definitions of the related objects
      self.related_objects = RelatedObjectHash.new
      self.association_types.keys.each do |type|
        self.related_objects[type] = RelatedObjectHash.new({})
      end
      self.related_objects[:scope] = RelatedObjectHash.new({})
      
      self.define_association_methods
      
    end

    # module methods to include the proper associations in various libraries - this is usually loaded in Railties
    def self.activate_active_record
      ActiveRecord::Base.class_eval do
        include ApiResource::AssociationActivation
        self.activate_associations(:has_many_remote => :has_many_remote, :belongs_to_remote => :belongs_to_remote, :has_one_remote => :has_one_remote)
      end
    end

    module ClassMethods
      
      # Define the methods for creating and testing for associations, unfortunately
      # scopes are different enough to require different methods :(
      def define_association_methods
        self.association_types.each_key do |assoc|
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{assoc}(*args)
              options = args.extract_options!
              options = options.with_indifferent_access
              # Raise an error if we have multiple args and options
              raise "Invalid arguments to #{assoc}" unless options.blank? || args.length == 1
              args.each do |arg|
                klass_name = (options[:class_name] ? options[:class_name].to_s.classify : arg.to_s.classify)
                # add this to any descendants - the other methods etc are handled by inheritance
                ([self] + self.descendants).each do |klass|
                  #We need to merge upon itself to generate a new object since the children all share their related objects with each other
                  klass.related_objects = klass.related_objects.merge(:#{assoc} => klass.related_objects[:#{assoc}].merge(arg.to_sym => klass_name))
                end
                # We need to define reader and writer methods here
                define_association_as_attribute(:#{assoc}, arg)
              end
            end
          
            def #{assoc}?(name)
              return self.related_objects[:#{assoc}][name.to_s.pluralize.to_sym].present? || self.related_objects[:#{assoc}][name.to_s.singularize.to_sym].present?
            end
          
            def #{assoc}_class_name(name)
              raise "No such" + :#{assoc}.to_s + " association on #{name}" unless self.#{assoc}?(name)
              return self.find_namespaced_class_name(self.related_objects[:#{assoc}][name.to_sym])
            end            

          EOE
          # For convenience we will define the methods for testing for the existence of an association
          # and getting the class for an association as instance methods too to avoid tons of self.class calls
          self.class_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{assoc}?(name)
              return self.class.#{assoc}?(name)
            end

            def #{assoc}_class_name(name)
              return self.class.#{assoc}_class_name(name)
            end
          EOE
        end
      end
      
      def association?(assoc)
        self.related_objects.any? do |key, value|
          next if key.to_s == "scope"
          value.detect { |k,v| k.to_sym == assoc.to_sym }
        end
      end
      
      def association_names
        # structure is {:has_many => {"myname" => "ClassName"}}
        self.related_objects.clone.delete_if{|k,v| k.to_s == "scope"}.collect{|k,v| v.keys.collect(&:to_sym)}.flatten
      end
      
      def association_class_name(assoc)
        raise ArgumentError, "#{assoc} is not a valid association of #{self}" unless self.association?(assoc)
        result = self.related_objects.detect do |key,value|
          ret = value.detect{|k,v| k.to_sym == assoc.to_sym }
          return self.find_namespaced_class_name(ret[1]) if ret
        end
      end
      
      def clear_associations
        self.related_objects.each do |_, val|
          val.clear
        end
      end
      
      protected
        def define_association_as_attribute(assoc_type, assoc_name)
          # set up dirty tracking for associations
          
          self.class_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{assoc_name}
              self.attributes[:#{assoc_name}] ||= #{self.association_types[assoc_type.to_sym].to_s.classify}ObjectProxy.new(self.association_class_name('#{assoc_name}'), nil, self)
            end
            def #{assoc_name}=(val)
              # get old internal object
              old_internal_object = self.#{assoc_name}.internal_object
              self.#{assoc_name}.internal_object = val
              #{assoc_name}_will_change! unless self.#{assoc_name} == old_internal_object
              self.#{assoc_name}.internal_object
            end
            def #{assoc_name}?
              self.#{assoc_name}.internal_object.present?
            end
          EOE
        end
        
        def find_namespaced_class_name(klass)
          # return the name if it is itself namespaced
          return klass if klass =~ /::/
          ancestors = self.name.split("::")
          if ancestors.size > 1
            receiver = Object
            namespaces = ancestors[0..-2].collect do |mod|
              receiver = receiver.const_get(mod)
            end
            if namespace = namespaces.reverse.detect{|ns| ns.const_defined?(klass, false)}
              return namespace.const_get(klass).name
            end
          end

          return klass
        end
      
    end
    
    module InstanceMethods
      def association?(assoc)
        self.class.association?(assoc)
      end
      
      def association_class_name(assoc)
        self.class.association_class_name(assoc)
      end
      
      # list of all association names
      def association_names
        self.class.association_names
      end
    end

  end
  
end