module ApiResource
  
  module Attributes
    
    extend ActiveSupport::Concern
    include ActiveModel::Dirty
    
    included do
      
      alias_method_chain :save, :dirty_tracking
      
      class_inheritable_accessor :attribute_names, :public_attribute_names, :protected_attribute_names
      
      attr_accessor :attributes
      
      # Override the getter to initialize to a blank hash
      self.class_eval <<-EOE, __FILE__, __LINE__ + 1
        def attributes
          return @attributes if @attributes
          @attributes = HashWithIndifferentAccess.new
          self.class.attribute_names.each do |attr|
            @attributes[attr] = nil
          end
          return @attributes
        end
      EOE
      
      self.attribute_names = []
      self.public_attribute_names = []
      self.protected_attribute_names = []
      
    end
    
    module ClassMethods
      
      # Make a list of known attributes about this record
      # and define getters and setters for all of them
      def known_attributes(*args)
        # Define the methods for dirty tracking for these attributes
        define_attribute_methods args
        args.each do |arg|
          # Define the getters and setters for this attribute
          self.attribute_names << arg.to_sym
          self.public_attribute_names << arg.to_sym
          # Eval with a string is slower to define but faster to call, since this will
          # only be defined once but called many times class_eval is our friend
          self.class_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{arg}=(val)
              #{arg}_will_change! unless self.#{arg} == val
              self.attributes[:#{arg}] = val
            end
            
            def #{arg}
              self.attributes[:#{arg}]
            end
            
            def #{arg}?
              !self.attributes[:#{arg}].nil?
            end
          EOE
        end
        self.attribute_names.uniq!
        self.public_attribute_names.uniq!
      end
      
      def protected_attributes(*args)
        # no point in using dirty tracking these cannot be modified
        args.each do |arg|
          self.attribute_names << arg.to_sym
          self.protected_attribute_names << arg.to_sym
          
          self.class_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{arg}
              self.attributes[:#{arg}]
            end
            
            def #{arg}?
              !self.attributes[:#{arg}].nil?
            end
            
            def #{arg}=
              raise "#{arg} is a protected attribute and cannot be assigned"
            end
          EOE
        end
        self.attribute_names.uniq!
        self.protected_attribute_names.uniq!
      end
      
      def attribute?(name)
        self.attribute_names.include?(name.to_sym)
      end
    end
    
    module InstanceMethods
      
      # Define save to work with dirty tracking
      def save_with_dirty_tracking(*args)
        if save_without_dirty_tracking
          @previously_changed = changes
          @changed_attributes.clear
          return true
        end
        
        return false
      end
      
      # Temporary attributes will never be serialized
      def temporary_attributes(*attrs)
        attrs.each do |attr|
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{attr}=(val)
              self.attributes[:#{attr}] = val
            end
            
            def #{attr}
              self.attributes[:#{attr}]
            end
            
            def #{attr}?
              !self.attributes[:#{attr}].nil?
            end
          EOE
        end
      end
      
      # Use this method to set the current attributes as the defaults
      # and set them all as unchanged
      def set_attributes_as_current(*attrs)
        attrs = self.class.public_attribute_names if attrs.blank?
        attrs.each do |attr|
          @changed_attributes.delete(attr.to_s)
        end
      end
      
      # Use this method to revert all changes to this record
      def reset_attribute_changes(*attrs)
        attrs = self.class.public_attribute_names if attrs.blank?
        attrs.each do |attr|
          # Reset the attribute and then clear it from changed attributes
          self.send("#{attr}=", self.send("#{attr}_was"))
        end
        set_attributes_as_current(*attrs)
      end
      
      # Returns true if name is a known attribute
      def attribute?(name)
        self.class.attribute?(name)
      end
      
      def respond_to?(sym)
        # Check if this is an attribute
        if sym =~ /\?$/
          return true if self.class.attribute_names.include?($`)
        elsif sym =~ /=$/
          return true if self.class.public_attribute_names.include?($`)
        else
          return true if self.class.attribute_names.include?(sym.to_sym)
        end
        super
      end
      
    end
    
  end
  
end