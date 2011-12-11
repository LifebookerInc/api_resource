module ApiResource

  module Attributes
  
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    
    included do
      
      alias_method_chain :save, :dirty_tracking
      
      class_inheritable_accessor :attribute_names, :public_attribute_names, :protected_attribute_names
      
      attr_reader :attributes
      
      self.attribute_names = []
      self.public_attribute_names = []
      self.protected_attribute_names = []
      
      define_method(:attributes) do
        return @attributes if @attributes
        # Otherwise make the attributes hash of all the attributes
        @attributes = HashWithIndifferentAccess.new
        self.class.attribute_names.each do |attr|
          @attributes[attr] = self.send("#{attr}")
        end
        @attributes
      end
      
    end
    
    module ClassMethods
      
      def define_attributes(*args)
        # This is provided by ActiveModel::AttributeMethods, it should define the basic methods
        # but we need to override all the setters so we do dirty tracking
        define_attribute_methods args
        args.each do |arg|
          self.attribute_names << arg.to_sym
          self.public_attribute_names << arg.to_sym
          
          # Override the setter for dirty tracking
          self.class_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{arg}
              self.attributes[:#{arg}]
            end
          
            def #{arg}=(val)
              #{arg}_will_change! unless self.#{arg} == val
              self.attributes[:#{arg}] = val
            end
            
            def #{arg}?
              self.attributes[:#{arg}].present?
            end
          EOE
        end
        self.attribute_names.uniq!
        self.public_attribute_names.uniq!
      end
      
      def define_protected_attributes(*args)
        define_attribute_methods args
        args.each do |arg|
          self.attribute_names << arg.to_sym
          self.protected_attribute_names << arg.to_sym
          
          # These attributes cannot be set, throw an error if you try
          self.class_eval <<-EOE, __FILE__, __LINE__ + 1

            def #{arg}
              self.attributes[:#{arg}]
            end
          
            def #{arg}=(val)
              raise "#{arg} is a protected attribute and cannot be set"
            end
            
            def #{arg}?
              self.attributes[:#{arg}].present?
            end
          EOE
        end
        self.attribute_names.uniq!
        self.protected_attribute_names.uniq!
      end
      
      def attribute?(name)
        self.attribute_names.include?(name.to_sym)
      end
      
      def protected_attribute?(name)
        self.protected_attribute_names.include?(name.to_sym)
      end
      
      def clear_attributes
        self.attribute_names.clear
        self.public_attribute_names.clear
        self.protected_attribute_names.clear
      end
    end
    
    module InstanceMethods
      
      # set new attributes
      def attributes=(new_attrs)
        new_attrs.each_pair do |k,v|
          self.send("#{k}=",v) unless k.to_sym == :id
        end
        new_attrs
      end
      
      def save_with_dirty_tracking(*args)
        if save_without_dirty_tracking(*args)
          @previously_changed = self.changes
          @changed_attributes.clear
          return true
        else
          return false
        end
      end
      
      def set_attributes_as_current(*attrs)
        @changed_attributes.clear and return if attrs.blank?
        attrs.each do |attr|
          @changed_attributes.delete(attr.to_s)
        end
      end
      
      def reset_attribute_changes(*attrs)
        attrs = self.class.public_attribute_names if attrs.blank?
        attrs.each do |attr|
          self.send("reset_#{attr}!")
        end
        
        set_attributes_as_current(*attrs)
      end
      
      def attribute?(name)
        self.class.attribute?(name)
      end
      
      def protected_attribute?(name)
        self.class.protected_attribute?(name)
      end
      
      def respond_to?(sym)
        if sym =~ /\?$/
          return true if self.attribute?($`)
        elsif sym =~ /=$/
          return true if self.class.public_attribute_names.include?($`)
        else
          return true if self.attribute?(sym.to_sym)
        end
        super
      end
    end
    
  end
  
end