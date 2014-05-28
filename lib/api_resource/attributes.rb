module ApiResource

  #
  # Error raised when accessing an attribute in an invalid
  # way such as trying to write to a protected attribute
  #
  # @author [ejlangev]
  #
  class AttributeAccessError < NoMethodError
  end

  module Attributes

    extend ActiveSupport::Concern

    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty

    included do

      # include ApiResource::Typecast if it isn't already
      include ApiResource::Typecast

      alias_method_chain :save, :dirty_tracking

      # Set up some class attributes for managing all of
      # this
      class_attribute(
        :attribute_names,
        :public_attribute_names,
        :protected_attribute_names,
        :attribute_types,
        :primary_key,
        :attribute_method_module
      )
      # Initialize those class attributes
      self.attribute_names = []
      self.public_attribute_names = []
      self.protected_attribute_names = []
      self.attribute_types = {}.with_indifferent_access

      self.primary_key = :id
      self.attribute_method_module = Module.new

      include self.attribute_method_module
      # This method is important for reloading an object. If the
      # object has already been loaded, its associations will trip
      # up the load method unless we pass in the internal objects.
      #
      # TODO: This seems like kind of a hack that shouldn't be
      # necessary.  Remove it at some point during the refactoring
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
      #
      # Wrapper method to define all of the attributes (public and protected)
      # for this Class.  This should be called with a locked mutex to
      # prevent multiple threads from defining attributes at the same time
      #
      # @return [Boolean] true
      def define_all_attributes
        if self.resource_definition["attributes"]
          # First we need to clear out the old values and clone them
          self.attribute_names = []
          self.public_attribute_names = []
          self.protected_attribute_names = []
          self.attribute_types = {}.with_indifferent_access
          # First define all public attributes
          define_attributes(
            *self.resource_definition['attributes']['public'],
            access_level: :public
          )
          # Then define all private attributes
          define_attributes(
            *self.resource_definition['attributes']['protected'],
            access_level: :protected
          )
        end
        true
      end

      #
      # Sets up the attributes for this class, can be called multiple
      # times to add more attributes.  Again meant to be called with a locked
      # mutex for thread safety
      #
      # @param  *args [Array] List of attributes to define and optional
      # hash as a last parameter
      #
      # @return [Boolean] Always true
      def define_attributes(*args)
        options = args.extract_options!
        options[:access_level] ||= :public
        # Initialize each attribute
        args.each do |arg|
          self.initialize_attribute(
            Array.wrap(arg),
            options[:access_level]
          )
        end

        self.define_attribute_methods(
          args,
          options[:access_level]
        )
      end

      #
      # Adds the attribute into some internal data structures but does
      # not define any methods for it
      #
      # @param  arg [Array] A 1 or 2 element array holding an
      # attribute name and optionally a type for that attribute
      # @param  access_level [Symbol] Either :protected or :public based on
      # the access level for this attribute
      #
      # @return [Boolean] Always true
      def initialize_attribute(attr, access_level)
        attr_name = attr[0].to_sym
        attr_type = (attr[1] || :unknown).to_sym

        # Look for the typecaster, raise an error if one is not found
        typecaster = self.typecasters[attr_type]
        if typecaster.nil?
          raise TypecasterNotFound, "#{attr_type} is an unknown type"
        end
        # Map the attribute name to the typecaster
        self.attribute_types[attr_name] = typecaster
        # Add the attribute to the proper list
        if access_level == :public
          if self.protected_attribute?(attr_name)
            raise ArgumentError, "Illegal change of attribute access level for #{attr_name}"
          end

          self.public_attribute_names << attr_name
        else
          if self.public_attribute?(attr_name)
            raise ArgumentError, "Illegal change of attribute access level for #{attr_name}"
          end

          self.protected_attribute_names << attr_name
        end
        self.attribute_names << attr_name
        true
      end

      #
      # Defines the attribute methods in a new module which
      # is then included in this class.  Meant to be called with
      # a locked mutex
      #
      # @param  args [Array] List of attributes to define
      # @param  access_level [Symbol] :protected or :public
      #
      # @return [Boolean] Always true
      def define_attribute_methods(attrs, access_level)
        self.attribute_method_module.module_eval do
          attrs.each do |attr|
            # Normalize for attributes without types
            attr_name = Array.wrap(attr).first
            # Define reader and huh methods
            self.module_eval <<-EOE, __FILE__, __LINE__ + 1
              def #{attr_name}
                read_attribute(:#{attr_name})
              end

              def #{attr_name}?
                read_attribute(:#{attr_name}).present?
              end
            EOE
            # Define a writer if this is public
            if access_level == :public
              self.module_eval <<-EOE, __FILE__, __LINE__ + 1
                def #{attr_name}=(new_val)
                  write_attribute(:#{attr_name}, new_val)
                end
              EOE
            end
          end
        end

        # Now we get all the attribute names as symbols
        # and define_attribute_methods for dirty tracking
        attrs = attrs.collect do |a|
          Array.wrap(a).first.to_sym
        end

        super(attrs)
        true
      end

      #
      # Returns true if the provided name is an attribute
      # of this class
      #
      # @param  name [Symbol] The name of the potential attribute
      #
      # @return [Boolean] True if an attribute with the given name exists
      def attribute?(name)
        self.attribute_names.include?(name.to_sym)
      end

      #
      # Returns true if the provided name is a protected attribute
      # @param  name [Symbol] Name of the potential attribute
      #
      # @return [Boolean] True if a protected attribute with the given name exists
      def protected_attribute?(name)
        self.protected_attribute_names.include?(name.to_sym)
      end

      #
      # Returns true if the provided name is a public attribute
      # @param  name [Symbol] Name of the potential attribute
      #
      # @return [Boolean] True if a public attribute with the given name exists
      def public_attribute?(name)
        self.public_attribute_names.include?(name.to_sym)
      end

      #
      # Removes all attributes from this class but does _NOT_
      # undefine their methods
      #
      # @return [Boolean] Always true
      def clear_attributes
        self.attribute_names.clear
        self.public_attribute_names.clear
        self.protected_attribute_names.clear

        true
      end

    end

    #
    # Override for initialize to set up attribute and
    # attributes cache
    #
    # @param  *args [Array] Arguments to initialize,
    # ignored in this case
    #
    # @return [Object] The object in question
    def initialize(*args)
      @attributes = HashWithIndifferentAccess[ self.class.attribute_names.zip([]) ]
      @attributes_cache = HashWithIndifferentAccess.new
      @previously_changed = HashWithIndifferentAccess.new
      @changed_attributes = HashWithIndifferentAccess.new
      super()
    end

    #
    # Reads an attribute typecasting if necessary
    # and setting the cache so as to only typecast
    # the one time.  Takes a block which is called if the
    # attribute is not found
    #
    # @param  attr_name [Symbol] The name of the attribute to read
    #
    # @return [Object] The value of the attribute or nil if it
    # is not found
    def read_attribute(attr_name)
      attr_name = attr_name.to_sym

      @attributes_cache[attr_name] || @attributes_cache.fetch(attr_name) do
        data = @attributes.fetch(attr_name) do
          # This statement overrides id to return the primary key
          # if it is set to something other than :id
          if attr_name == :id && self.class.primary_key != attr_name
            return read_attribute(self.class.primary_key)
          end

          # For some reason hashes return false for key? if the value
          # at that key is nil.  It also executes this block for fetch
          # when it really shouldn't.  Detect that error here and give
          # back nil for data
          if @attributes.keys.include?(attr_name)
            nil
          else
            # In this case the attribute was truly not found, if we're
            # given a block execute that otherwise return nil
            return block_given? ? yield(attr_name) : nil
          end
        end
        # This sets and returns the typecasted value
        @attributes_cache[attr_name] = self.typecast_attribute_for_read(
          attr_name,
          data
        )
      end
    end

    #
    # Reads the attribute directly out of the attributes hash
    # without applying any typecasting
    # @param  attr_name [Symbol] The name of the attribute to be read
    #
    # @return [Object] The untypecasted value of the attribute or nil
    # if that attribute is not found
    def read_attribute_before_type_cast(attr_name)
      return @attributes[attr_name.to_sym]
    end

    #
    # Writes an attribute, first typecasting it to the proper type with
    # typecast_attribute_for_write and then setting it in the attributes
    # hash.  Raises MissingAttributeError if no such attribute exists
    #
    # @param  attr_name [Symbol] The name of the attribute to set
    # @param  value [Object] The value to write
    #
    # @return [Object] The value parameter is always returned
    def write_attribute(attr_name, value)
      attr_name = attr_name.to_sym
      # Change a write attribute for id to the primary key
      attr_name = self.class.primary_key if attr_name == :id && self.class.primary_key
      # The value we expect here should be typecasted for going to
      # the api
      typed_value = self.typecast_attribute_for_write(attr_name, value)

      if attribute_changed?(attr_name)
        old = changed_attributes[attr_name]
        changed_attributes.delete(attr_name) if old == typed_value
      else
        old = clone_attribute_value(:read_attribute, attr_name)
        changed_attributes[attr_name] = old if old != typed_value
      end

      # Remove this attribute from the attributes cache
      @attributes_cache.delete(attr_name)
      # Raise an error if this is not an attribute
      if !self.attribute?(attr_name)
        raise ActiveModel::MissingAttributeError.new(
          "can't write unknown attribute #{attr_name}",
          caller(0)
        )
      end
      # Raise another error if this is a protected attribute
      # if self.protected_attribute?(attr_name)
      #   raise ApiResource::AttributeAccessError.new(
      #     "cannot write to protected attribute #{attr_name}",
      #     caller(0)
      #   )
      # end
      @attributes[attr_name] = typed_value
      value
    end

    #
    # Returns the typecasted value of an attribute for being
    # read (calls from_api on the typecaster).  Raises
    # TypecasterNotFound if no typecaster exists for this attribute
    #
    # @param  attr_name [Symbol] The name of the attribute
    # @param  value [Object] The value to be typecasted
    #
    # @return [Object] The typecasted value
    def typecast_attribute_for_read(attr_name, value)
      self
        .find_typecaster(attr_name)
        .from_api(value)
    end

    #
    # Returns the typecasted value of the attribute for being
    # written (calls to_api on the typecaster).  Raises
    # TypecasterNotFound if no typecaster exists for this attribute
    #
    # @param  attr_name [Symbol] The attribute in question
    # @param  value [Object] The value to be typecasted
    #
    # @return [Object] The typecasted value
    def typecast_attribute_for_write(attr_name, value)
      self
        .find_typecaster(attr_name)
        .to_api(value)
    end

    #
    # Returns a hash of attribute names as keys and typecasted values
    # as hash values
    #
    # @return [HashWithIndifferentAccess] Map from attr name to value
    def attributes
      hash = HashWithIndifferentAccess.new

      self.class.attribute_names.each_with_object(hash) do |name, attrs|
        attrs[name] = read_attribute(name)
      end
    end

    #
    # Handles mass assignment of attributes, including sanitizing them
    # for mass assignment. Which by default does nothing but would if you
    # were to use this in rails 4 or with strong_parameters
    #
    # @param  attrs [Hash] Hash of attributes to mass assign
    #
    # @return [Hash] The passed in attrs param (with keys symbolized)
    def attributes=(attrs)
      unless attrs.respond_to?(:symbolize_keys)
        raise ArgumentError, 'You must pass a hash when assigning attributes'
      end

      return if attrs.blank?

      attrs = attrs.symbolize_keys
      # First deal with sanitizing for mass assignment
      # this raises an error if attrs violates mass assignment rules
      attrs = self.sanitize_for_mass_assignment(attrs)

      attrs.each do |name, value|
        self._assign_attribute(name, value)
      end

      attrs
    end

    #
    # Reads an attribute and raises MissingAttributeError
    #
    # @param  attr_name [Symbol] The attribute to read
    #
    # @return [Object] The value of the attribute
    def [](attr_name)
      read_attribute(attr_name) do |n|
        self.missing_attribute(attr_name, caller(0))
      end
    end

    #
    # Write the value to the given attribute
    # @param  attr_name [Symbol] The attribute to write
    # @param  value [Object] The value to be written
    #
    # @return [Object] Returns the value parameter
    def []=(attr_name, value)
      write_attribute(attr_name, value)
    end

    #
    # Wrapper for the class method attribute? that
    # returns true if the name parameter is the name of
    # any attribute
    #
    # @param  name [Symbol] The name to query
    #
    # @return [Boolean] True if the name param is the name
    # of an attribute
    def attribute?(name)
      self.class.attribute?(name)
    end

    #
    # Wrapper for the class method protected_attribute?
    #
    # @param  name [Symbol] The name to query
    #
    # @return [Boolean] True if name is a protected attribute
    def protected_attribute?(name)
      self.class.protected_attribute?(name)
    end

    #
    # Wrapper for the class method public_attribute?
    #
    # @param  name [Symbol] The name to query
    #
    # @return [Boolean] True if name is a public attribute
    def public_attribute?(name)
      self.class.public_attribute?(name)
    end

    #
    # Override for the save method to update our dirty tracking
    # of attributes
    #
    # @param  *args [Array] Used to clear changes on any associations
    # embedded in this save provided it succeeds
    #
    # @return [Boolean] True if the save succeeded, false otherwise
    def save_with_dirty_tracking(*args)
      if save_without_dirty_tracking(*args)
        self.make_changes_current
        if args.first.is_a?(Hash) && args.first[:include_associations]
          args.first[:include_associations].each do |assoc|
            Array.wrap(self.send(assoc).internal_object).each(&:make_changes_current)
          end
        end
        return true
      else
        return false
      end
    end

    #
    # Override to respond_to? for finding attribute methods even
    # if they are not defined
    #
    # @param  sym [Symbol] The method that we may respond to
    # @param  include_private_methods = false [Boolean] Whether or not
    # we should consider private methods
    #
    # @return [Boolean] True if we respond to sym
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

    def method_missing(sym, *args, &block)
      sym = sym.to_sym

      # Maybe the resource definition sucks...
      if self.class.resource_definition_is_invalid?
        self.class.reload_resource_definition
      end

      # If we don't respond by now...
      if self.respond_to?(sym)
        return self.send(sym, *args, &block)
      elsif @attributes.keys.symbolize_array.include?(sym)
        # Try returning the attributes from the attributes hash
        return @attributes[sym]
      end

      # Fall back to class method_missing
      super
    end

    def make_changes_current
      @previously_changed = self.changes
      @changed_attributes.clear
    end

    def clear_changes(*attrs)
      @previously_changed = {}
      @changed_attributes = {}
      true
    end

    def reset_changes
      self.class.attribute_names.each do |attr_name|
        attr_name = attr_name.to_sym

        reset_attribute!(attr_name)
      end
      true
    end

    protected
      #
      # Default implementation that would be overridden by including
      # the behavior from strong parameters
      #
      # @param  attrs [Hash] Attributes to sanitize (by default do nothing)
      #
      # @return [Hash] Unmodified attrs
      def sanitize_for_mass_assignment(attrs)
        return attrs
      end

      #
      # Writes an attribute by proxying to the writer methods.
      # Raises MissingAttributeError if #{name}= does not exist
      #
      # @param  name [Symbol] The attribute to write
      # @param  value [Object] The value to write
      #
      # @return [Boolean] Always true
      def _assign_attribute(name, value)
        # special case if we are assigning a protected attribute
        # since it has no writer method
        if self.protected_attribute?(name)
          return self.write_attribute(name, value)
        end

        begin
          # Call the method only if it is public
          self.public_send("#{name}=", value)
        rescue NoMethodError
          # If we get a no method error we should re-raise it
          # if it wasn't because #{name}= is not defined
          if self.respond_to?("#{name}=")
            raise
          else
            # Otherwise we raise MissingAttributeError
            self.missing_attribute(name, caller(0))
          end
        end
      end

      #
      # Searches for the typecaster for the given attribute name
      # raising ApiResource::TypecasterNotFound if it
      # cannot find one
      #
      # @param  attr_name [Symbol] The attribute whose typecaster you're after
      #
      # @return [ApiResource::Typecaster] An object for typecasting attribute
      # values
      def find_typecaster(attr_name)
        attr_name = attr_name.to_sym

        typecaster = self.class.attribute_types[attr_name]

        if typecaster.nil?
          typecaster = ApiResource::Typecast::UnknownTypecaster
        end

        return typecaster
      end

      #
      # Helper for raising a MissingAttributeError
      #
      # @param  name [Symbol] The missing attribute's name
      # @param  backtrace [Object] The backtrace of where the
      # error occurred
      #
      # @return [type] [description]
      def missing_attribute(name, backtrace)
        raise ActiveModel::MissingAttributeError.new(
          "could not find attribute #{name}",
          backtrace
        )
      end

      def clone_attribute_value(meth, attr_name)
        attr_name = attr_name.to_sym

        result = self.send(meth, attr_name)

        return result.duplicable? ? result.clone : result
      end


    private

      # this is here for compatibility with ActiveModel::AttributeMethods
      # it is the fallback called in method_missing
      #
      # @param  name [Symbol] The attribute to read
      #
      # @return [Object] The value read
      def attribute(name)
        read_attribute(name)
      end

      # this is here for compatibility with ActiveModel::AttributeMethods
      # it is the fallback called in method_missing
      #
      # @param  name [Symbol] The attribute to
      # @param  val [Object] The value to assign
      #
      # @return [Object] val
      def attribute=(name, val)
        write_attribute(name, val)
      end

  end

end
