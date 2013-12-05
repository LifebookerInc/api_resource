module ApiResource

  #
  # Namespace that encapsulates behavior for defining
  # and constructing objects to manage associations
  #
  # @author [ejlangev]
  #
  module AssociationBuilder

    extend ActiveSupport::Autoload

    autoload :AbstractBuilder
    autoload :BelongsToBuilder
    autoload :HasManyBuilder
    autoload :HasOneBuilder

    #
    # Error class for someone trying to instantiate an association
    # class that does not exist
    #
    # @author [ejlangev]
    #
    class AssociationClassNotFound < ApiResource::Error
    end

    #
    # Error class for someone trying to instantiate an
    # association type that does not exist
    #
    # @author [ejlangev]
    #
    class AssociationTypeNotFound < ApiResource::Error
    end

    #
    # Factory method for getting the correct type
    # of association builder object to instantiate for
    # a given association type
    #
    # @param  association_type [Symbol] Symbol representing the type of association
    #
    # @raise [AssociationTypeNotFound] Error if it cannot find the proper subclass for a given association type
    #
    # @return [Class] A concrete subclass of AbstractBuilder
    def self.get_class(association_type)
      # Turn the association type into the builder name
      builder_name = "#{association_type.to_s.classify}Builder"
      # Check if the builder exists
      unless self.const_defined?(builder_name)
        raise AssociationTypeNotFound.new(
          "No known builder for association type #{association_type}"
        )
      end

      return self.const_get(builder_name)
    end

  end

end