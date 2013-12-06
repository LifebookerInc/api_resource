require 'active_support'
require 'active_support/string_inquirer'

module ApiResource

  module Associations

    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :AssociationProxy
    autoload :BelongsToRemoteObjectProxy
    autoload :HasManyRemoteObjectProxy
    autoload :HasManyThroughRemoteObjectProxy
    autoload :HasOneRemoteObjectProxy
    autoload :MultiObjectProxy
    autoload :RelatedObjectHash
    autoload :SingleObjectProxy

    included do

      unless self.ancestors.include?(ApiResource::AssociationActivation)
        raise Exception.new(
          "Can't include Associations without AssociationActivation"
        )
      end

      self.define_association_methods

    end

    #
    # Class to raise when trying to work with an association
    # that does not exist
    #
    # @author [ejlangev]
    #
    class AssociationNotFound < ApiResource::Error
    end

    #
    # Class to raise when assigning an association an invalid
    # value
    #
    # @author [ejlangev]
    #
    class AssociationTypeMismatch < ApiResource::Error
    end

    # module methods to include the proper associations in various libraries - this is usually loaded in Railties
    def self.activate_active_record
      ActiveRecord::Base.class_eval do
        include ApiResource::AssociationActivation
        self.activate_associations(
          :has_many_remote => :has_many_remote,
          :belongs_to_remote => :belongs_to_remote,
          :has_one_remote => :has_one_remote,
        )
      end
    end

    module ClassMethods

      #
      # Returns true if the symbol is the name of an
      # association for this class
      #
      # @param  assoc [Symbol] The name to query
      #
      # @return [Boolean] True if the association exists
      def association?(assoc)
        self.lookup_association(assoc.to_sym).present?
      end

      #
      # Cache the association builders on the class level
      # so each class stores the builders that were defined on it
      # directly
      #
      # @return [Hash]
      def association_builders
        @association_builders ||= Hash.new
      end

      #
      # Shortcut to get the class name for an association
      #
      # @param  assoc [Symbol] The association name
      #
      # @return [String] The class name or nil if that is not found
      def association_class_name(assoc)
        self.lookup_association(assoc.to_sym)
            .try(:association_class_name)
      end

      #
      # Return the class for this association
      #
      # @param  assoc [Symbol] The association name
      #
      # @raise [ApiResource::AssociationBuilder::AssociationClassNotFound]
      #
      # @return [Class]
      def association_class(assoc)
        self.lookup_association(assoc.to_sym)
          .try(:association_class)
      end

      #
      # Returns a list of all the association names for
      # this class as symbols.
      #
      # @return [Array<Symbol>]
      def association_names
        if self == ApiResource::Base
          return []
        end

        tmp = self.superclass.association_names
        tmp = self.association_builders.keys + tmp

        return tmp.uniq
      end

      #
      # Defines the methods for creating associations to this
      # class
      #
      # @return [NilClass] Always returns nil
      def define_association_methods
        self.association_types.each_key do |assoc|
          self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{assoc}(*args)
              builder = ApiResource::AssociationBuilder.get_class(:#{assoc})
              builder = builder.new(
                self,
                *args
              )

              self.association_builders[builder.association_name] = builder
              # Now include the generated methods for this association
              include builder.generated_methods_module
              # Give back the builder object
              return builder
            end

            def #{assoc}?(name)
              :#{assoc} == self.lookup_association(name.to_sym)
                               .try(:association_type)
            end

            # Gives back the class name for an association
            def #{assoc}_class_name(name)
              return nil unless self.#{assoc}?(name)
              self.lookup_association(name.to_sym)
                  .try(:association_class_name)
            end
          EOE
        end

        nil
      end

      #
      # Looks up an association first searching in this
      # class and then in the class hierarchy up to ApiResource::Base.
      # Returns the association builder object or nil if one is not found.
      #
      # @param  assoc_name [Symbol] The association builder to find
      #
      # @return [ApiResource::AssociationBuilder::AbstractBuilder]
      def lookup_association(assoc_name)
        if self == ApiResource::Base
          return nil
        end

        builder = self.association_builders[assoc_name]
        # Builder could be nil, if it is consult the superclass
        return builder || self.superclass.lookup_association(assoc_name)
      end


      protected

        #
        # Wrapper method to define all associations from the
        # resource definition
        #
        # @return [Boolean] true
        def define_all_associations
          if self.resource_definition["associations"]
            self.resource_definition["associations"].each_pair do |key, hash|
              hash.each_pair do |assoc_name, assoc_options|
                self.send(key, assoc_name, assoc_options)
              end
            end
          end
          true
        end

    end

    #
    # Instance level method for testing if something
    # is an association
    #
    # @param  assoc [Symbol] Association name to check for
    #
    # @return [Boolean] True if the association exists
    def association?(assoc)
      self.class.association?(assoc)
    end

    #
    # Holds the current association proxy objects
    # for this object.
    #
    # @return [Hash] Map from association name symbol to proxy
    def associations
      @associations ||= Hash.new
    end

    #
    # Returns the class for a given association
    #
    # @param  assoc [Symbol] Association name to query
    #
    # @raise [ApiResource::AssociationBuilder::AssociationClassNotFound]
    #
    # @return [Class] The class if it exists, otherwise nil
    def association_class(assoc)
      self.class.association_class(assoc)
    end

    #
    # Returns the class name for a given association
    #
    # @param  assoc [Symbol] Association name to query
    #
    # @return [String] The name of the class
    def association_class_name(assoc)
      self.class.association_class_name(assoc)
    end

    #
    # Returns a list of the names of all the associations this
    # class knows about as symbols
    #
    # @return [Array<Symbol>]
    def association_names
      self.class.association_names
    end

    protected

      #
      # Fetches or creates an association proxy for this
      # object
      #
      # @param  assoc_name [Symbol] Association name
      #
      # @raise [ApiResource::Associations::AssociationNotFound]
      #
      # @return [ApiResource::Associations::AssociationProxy]
      def read_association(assoc_name)
        return fetch_or_build_association_proxy(
          assoc_name
        )
      end

      #
      # Fetches or creates an association proxy for this object
      # and then delegates the assignment to its assign method
      #
      # @param  assoc_name [Symbol] Association name to write
      # @param  val [Object] Value to assign to
      #
      # @raise [ApiResource::Associations::AssociationNotFound]
      #
      # @return [Object] Returns val
      def write_association(assoc_name, val)
        proxy = fetch_or_build_association_proxy(
          assoc_name
        )

        proxy.__send__(:assign, val)
      end

    private

      def fetch_or_build_association_proxy(assoc_name)
        self.associations[assoc_name] ||= begin
          builder = self.class.lookup_association(assoc_name)

          if builder.present?
            builder.association_proxy(self)
          else
            raise AssociationNotFound.new(
              "Could not find association #{assoc_name}"
            )
          end
        end

      end

  end

end
