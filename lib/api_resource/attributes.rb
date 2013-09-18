module ApiResource

  module Attributes
  
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    
    included do

      # include ApiResource::Typecast if it isn't already
      include ApiResource::Typecast
      
      alias_method_chain :save, :dirty_tracking
      
      class_attribute(
        :attribute_names, 
        :public_attribute_names, 
        :protected_attribute_names, 
        :attribute_types
      )

      self.attribute_names = []
      self.public_attribute_names = []
      self.protected_attribute_names = []
      self.attribute_types = {}.with_indifferent_access
      

      # This method is important for reloading an object. If the
      # object has already been loaded, its associations will trip
      # up the load method unless we pass in the internal objects.

      define_method(:attributes_without_proxies) do
        attributes = @attributes

        if attributes.nil?
          attributes = self.class.attribute_names.each do |attr|
            attributes[attr] = self.send("#{attr}")
          end
        end

        attributes.each do |k,v|
          if v.respond_to?(:internal_object)
            if v.internal_object.present?
              internal = v.internal_object
              if internal.is_a?(Array)
                attributes[k] = internal.collect{|item| item.attributes}
              else
                attributes[k] = internal.attributes
              end
            else
              attributes[k] = nil
            end
          end
        end

        attributes
      end
      
    end
    
    module ClassMethods
      
      def define_attributes(*args)
        args.each do |arg|
          self.store_attribute_data(arg, :public)
        end
        self.attribute_names.uniq!
        self.public_attribute_names.uniq!
      end
      
      def define_protected_attributes(*args)
        args.each do |arg|
          self.store_attribute_data(arg, :protected)
        end
        self.attribute_names.uniq!
        self.protected_attribute_names.uniq!
      end

      def define_accessor_methods(meth)
        # Override the setter for dirty tracking
        self.class_eval <<-EOE, __FILE__, __LINE__ + 1
          def #{meth}
            read_attribute(:#{meth})
          end
        
          def #{meth}=(new_val)
            write_attribute(:#{meth}, new_val)
          end
          
          def #{meth}?
            read_attribute(:#{meth}).present?
          end
        EOE
        # sets up dirty tracking
        define_attribute_method(meth)
      end

      def define_attribute_type(field, type)
        unless self.typecasters.keys.include?(type.to_sym)
          raise "#{type} is not a valid type" 
        end
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

      # stores the attribute type data and the name of the 
      # attributes we are creating
      def store_attribute_data(arg, type)
        if arg.is_a?(Array)
          self.define_attribute_type(arg.first, arg.second)
          arg = arg.first
        end
        self.attribute_names += [arg.to_sym]
        self.send(
          "#{type}_attribute_names=",
          self.send("#{type}_attribute_names") + [arg.to_sym]
        )
        self.define_accessor_methods(arg)
      end

    end

    # override the initializer to set up some default values
    def initialize(*args)
      @attributes = @attributes_cache = HashWithIndifferentAccess.new
    end

    def attributes
      attrs = {}
      self.attribute_names.each{|name| attrs[name] = read_attribute(name)}
      attrs
    end

    # set new attributes
    def attributes=(new_attrs)
      new_attrs.each_pair do |k,v|
        if self.protected_attribute?(k)
          raise Exception.new(
            "#{k} is a protected attribute and cannot be mass-assigned"
          )
        end
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

    def read_attribute(name)
      self.typecasted_attribute(name.to_sym)
    end

    def write_attribute(name, val)
      old_val = read_attribute(name)
      new_val = val.nil? ? nil : self.typecast_attribute(name, val)

      unless old_val == new_val
        self.send("#{name}_will_change!")
      end
      # delete the old cached value and assign new val to both
      # @attributes and @attributes_cache
      @attributes_cache.delete(name.to_sym)
      @attributes[name.to_sym] = @attributes_cache[name.to_sym] = new_val
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
    
    def default_value_for_field(field)
      case self.class.attribute_types[field.to_sym]
        when :array
          return []
        else
          return nil
      end
    end

    def typecasted_attribute(field)

      @attributes ||= HashWithIndifferentAccess.new
      @attributes_cache ||= HashWithIndifferentAccess.new

      if @attributes_cache.has_key?(field.to_sym)
        return @attributes_cache[field.to_sym]
      else
        # pull out of the raw attributes
        if @attributes.has_key?(field.to_sym)
          val = @attributes[field.to_sym]
        else
          val = self.default_value_for_field(field)
        end
        # now we typecast
        val = val.nil? ? nil : self.typecast_attribute(field, val)
        return @attributes_cache[field.to_sym] = val
      end
    end

    def typecast_attribute(field, val)
      # if we have a valid value and we are planning to typecast go 
      # into this case statement
      if self.class.attribute_types.include?(field.to_sym)
        caster = self.class.typecasters[self.class.attribute_types[field.to_sym]]
        if caster.present?
          val = caster.from_api(val)
        end
      end

      return val
    end

    private

    # this is here for compatibility with ActiveModel::AttributeMethods
    # it is the fallback called in method_missing
    def attribute(name)
      read_attribute(name)      
    end

    # this is here for compatibility with ActiveModel::AttributeMethods
    # it is the fallback called in method_missing
    def attribute=(name, val)
      write_attribute(name, val)      
    end
    
  end
  
end