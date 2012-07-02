module ApiResource

  module Attributes
  
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    
    included do
      
      alias_method_chain :save, :dirty_tracking
      
      class_attribute :attribute_names, :public_attribute_names, :protected_attribute_names, :attribute_types
      
      cattr_accessor :valid_typecasts; self.valid_typecasts = [:date, :time, :float, :integer, :int, :fixnum, :string, :array]

      attr_reader :attributes
      
      self.attribute_names = []
      self.public_attribute_names = []
      self.protected_attribute_names = []
      self.attribute_types = {}.with_indifferent_access
      
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
        args.each do |arg|
          if arg.is_a?(Array)
            self.define_attribute_type(arg.first, arg.second)
            arg = arg.first
          end
          self.attribute_names += [arg.to_sym]
          self.public_attribute_names += [arg.to_sym]
          
          # Override the setter for dirty tracking
          self.class_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{arg}
              attribute_with_default(:#{arg})
            end
          
            def #{arg}=(val)
              real_val = typecast_attribute(:#{arg}, val)
              #{arg}_will_change! unless self.#{arg} == real_val
              attributes[:#{arg}] = real_val
            end
            
            def #{arg}?
              attributes[:#{arg}].present?
            end
          EOE
        end
        self.attribute_names.uniq!
        self.public_attribute_names.uniq!
      end
      
      def define_protected_attributes(*args)
        args.each do |arg|
          
          if arg.is_a?(Array)
            self.define_attribute_type(arg.first, arg.second)
            arg = arg.first
          end

          self.attribute_names += [arg.to_sym]
          self.protected_attribute_names += [arg.to_sym]
          
          # These attributes cannot be set, throw an error if you try
          self.class_eval <<-EOE, __FILE__, __LINE__ + 1

            def #{arg}
              self.attribute_with_default(:#{arg})
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
      
      def define_attribute_type(field, type)
        raise "#{type} is not a valid type" unless self.valid_typecasts.include?(type.to_sym)
        self.attribute_types[field] = type.to_sym
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
    
    def respond_to?(sym, include_private_methods = false)
      if sym =~ /\?$/
        return true if self.attribute?($`)
      elsif sym =~ /=$/
        return true if self.class.public_attribute_names.include?($`)
      else
        return true if self.attribute?(sym.to_sym)
      end
      super
    end
    
    protected
    
    def attribute_with_default(field)
      self.attributes[field].nil? ? self.default_value_for_field(field) : self.attributes[field]
    end

    def default_value_for_field(field)
      case self.class.attribute_types[field.to_sym]
        when :array
          return []
        else
          return nil
      end
    end

    def typecast_attribute(field, val)
      return val unless self.class.attribute_types.include?(field)
      case self.class.attribute_types[field.to_sym]
        when :date
          return val.class == Date ? val.dup : Date.parse(val)
        when :time
          return val.class == Time ? val.dup : Time.parse(val)
        when :integer, :int, :fixnum
          return val.class == Fixnum ? val.dup : val.to_i rescue val
        when :float
          return val.class == Float ? val.dup : val.to_f rescue val
        when :string
          return val.class == String ? val.dup : val.to_s rescue val
        when :array
          return val.class == Array ? val.dup : Array.wrap(val)
        else
          # catches the nil case and just leaves it alone
          return val.dup rescue val
      end
    end
    
  end
  
end