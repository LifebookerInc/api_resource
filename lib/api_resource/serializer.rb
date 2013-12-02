module ApiResource

  #
  # Handles serialization for a given instance of ApiResource::Base with
  # a set of options
  #
  # @author [dlangevin]
  #
  class Serializer

    # @!attribute [r] options
    #   @return [HashWithIndifferentAccess]
    attr_reader :options

    # @!attribute [r] record
    #   @return [ApiResource::Base]
    attr_reader :record

    #
    # Constructor
    #
    # @param  record [ApiResource::Base] Record to serialize
    # @param  options = {} [Hash] Options supplied
    #
    # @option options [Array<Symbol,String>] except (Array<>) Attributes to
    # explicitly exclude
    # @option options [Array<Symbol,String] include_associations (Array<>)
    # Associations to explicitly include
    # @option options [Array<Symbol,String] include_extras (Array<>)
    # Attributes to explicitly include
    # @option options [Boolean] include_id (false) Whether or not to include
    # the primary key
    # @option options [Boolean] include_nil_attributes (false) Whether or not
    # to include attributes that are blank/nil in the serialized hash
    #
    def initialize(record, options = {})
      @record = record
      @options = options.with_indifferent_access
    end

    #
    # Return our serialized object as a Hash
    #
    # @return [HashWithIndifferentAccess]
    def to_hash
      ret = HashWithIndifferentAccess.new
      ret.merge!(self.attributes_for_hash)
      ret.merge!(self.associations_for_hash)
      ret.merge!(self.add_on_data_for_hash)
      ret.merge!(self.association_foreign_keys_for_hash)
      ret
    end


    protected

    #
    # Data that is implicitly or explicitly added by options
    #
    # @return [Hash] Data to add on
    def add_on_data_for_hash
      {}.tap do |ret|
        # explicit inclusion of the record's id (used in nested updates)
        if self.options[:include_id] && !self.record.new_record?
          ret[:id] = self.record.id
        end
      end
    end

    #
    # Attribute data to include in the hash - this checks whether or not
    # to include a given attribute with {#include_attribute?}
    #
    # @return [Hash] Data from attributes
    def attributes_for_hash
      self.record.attributes.inject({}) do |accum, (key,val)|
        if self.include_attribute?(key, val)
          accum.merge(key => val)
        else
          accum
        end
      end
    end

    #
    # Data that is included due to foreign keys.
    #
    # @example
    #   tr = TestResource.new
    #   tr.belongs_to_object = BelongsToObject.find(10)
    #   Serializer.new(tr).to_hash #=> {:belongs_to_object_id => 10}
    #
    # @return [Hash] Data from foreign keys
    def association_foreign_keys_for_hash
      {}.tap do |ret|
        self.record.association_names.each do |name|
          # this is the method name
          # E.g. :belongs_to_object => :belongs_to_object_id
          method_name = self.record.class.association_foreign_key_field(name)
          # make sure we have changes
          next if self.record.changes[method_name].blank?
          # make sure we aren't in a prefix method
          next if self.is_prefix_field?(method_name)
          # add the changed value
          ret[method_name] = self.record.send(method_name)
        end
      end
    end

    #
    # Nested association data for the hash.  This checks whether or not
    # to include a given association with {#include_association?}
    #
    # @return [Hash] Data from associations
    def associations_for_hash
      self.record.association_names.inject({}) do |accum, assoc_name|
        if self.include_association?(assoc_name)
          # get the association
          assoc = self.record.send(assoc_name)
          options = self.options.merge(include_id: true)
          accum.merge(assoc_name => assoc.serializable_hash(options))
        else
          accum
        end
      end
    end

    #
    # List of all association names that are in our changes set
    #
    # @return [Array<Symbol>]
    def changed_associations
      @changed_associations ||= begin
        self.record.changes.keys.symbolize_array.select{ |k|
          self.record.association?(k)
        }
      end
    end

    #
    # Helper method to check if a blank value should be included
    # in the response
    #
    # @param  key [String, Symbol] Attribute name
    # @param  val [Mixed] Value to include
    #
    # @return [Boolean] Whether or not to include this key/value pair
    def check_blank_value(key, val)
      # if we explicitly want nil attributes
      return true if self.options[:include_nil_attributes]
      # or if the attribute has changed to nil
      return true if self.record.changes[key].present?
      # make sure our value isn't blank
      return !val.nil?
    end

    #
    # List of explicitly excluded attributes
    #
    # @return [type] [description]
    def excluded_keys
      @excluded_keys ||= begin
        ret = self.options[:except] || []
        ret.map(&:to_sym)
      end
    end

    #
    # Should we include this association in our hash?
    #
    # @param  association [Symbol] Association name to check
    #
    # @return [Boolean] Whether or not to include it
    def include_association?(association)
      # if we have explicitly requested this association we include it
      return true if self.included_associations.include?(association)
      return true if self.changed_associations.include?(association)
      # explicitly excluded
      return false if self.excluded_keys.include?(association)
      return false
    end

    #
    # Should we include this attribute?
    #
    # @param  attribute [String, Symbol] Field name
    # @param  val [Mixed] Field value
    #
    # @return [Boolean] Whether or not to include it
    def include_attribute?(attribute, val)
      attribute = attribute.to_sym
      # explicitly included
      return true if self.included_attributes.include?(attribute)
      # explicitly excluded
      return false if self.excluded_keys.include?(attribute)
      # make sure it's public
      return false unless self.public_attributes.include?(attribute)
      # make sure it's not already accounted for in the URL
      if self.is_prefix_field?(attribute)
        return false
      end
      # check to make sure the value is something we want to send
      return false unless self.check_blank_value(attribute, val)

      # default to true
      true
    end

    #
    # Associations explicitly included by the caller
    #
    # @return [Array<Symbol>]
    def included_associations
      @included_associations ||= begin
        self.options[:include_associations] ||= []
        self.options[:include_associations].collect(&:to_sym)
      end
    end

    #
    # Attributes explicitly included by the caller
    #
    # @return [Array<Symbol>]
    def included_attributes
      @included_attributes ||= begin
        ret = self.options[:include_extras] || []
        ret.map(&:to_sym)
      end
    end

    #
    # Whether or not a given attribute is accounted for in the
    # prefix for this class
    #
    # @param  attribute [Symbol] Attribute to check
    #
    # @example
    #   class TestResource
    #     prefix '/belongs_to_objects/:id/test_resources'
    #   end
    #
    #   tr = TestResource.new(:belongs_to_object_id => 10)
    #   Serializer.new(tr).to_hash #=> {}
    #
    #   tr.save #=> makes a call to /belongs_to_objects/10/test_resources
    #
    # @return [Boolean]
    def is_prefix_field?(attribute)
      self.record.prefix_attribute_names.include?(attribute.to_sym)
    end

    #
    # List of public attributes for the record
    #
    # @return [Array<Sumbol>]
    def public_attributes
      @public_attributes ||= begin
        self.record.attributes.keys.symbolize_array.reject{ |k|
          self.record.protected_attribute?(k)
        }
      end
    end
  end
end