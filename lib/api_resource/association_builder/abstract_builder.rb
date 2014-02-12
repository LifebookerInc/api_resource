module ApiResource

  module AssociationBuilder

    #
    # Superclass for the different types of association
    # builder objects
    #
    # @author [ejlangev]
    #
    class AbstractBuilder

      # @!attribute association_class
      # @return [Class] Class to instantiate for associated records
      attr_reader :association_class

      # @!attribute association_class_name
      # @return [String] The name of the class to use for associated records
      attr_reader :association_class_name

      # @!attribute association_name
      # @return [Symbol] The name of the association, also its reader/writer
      # method base name
      attr_reader :association_name

      # @!attribute association_type
      # @return [Symbol] The type of association, has_many, belongs_to, etc.
      attr_reader :association_type

      # @!attribute foreign_key
      # @return [Symbol] The foreign key field for this association
      attr_reader :foreign_key

      # @!attribute foreign_key_method
      # @return [Symbol] The name of the foreign key method that
      # will be defined on the owner class
      attr_reader :foreign_key_method

      # @!attribute generated_methods_module
      # @return [Module] Module containing the instance methods
      # to add to the class
      attr_reader :generated_methods_module

      # @!attribute owner_class
      # @return [Class] The class that has the association
      attr_reader :owner_class

      #
      # @param  klass [Class] The class the association is being built for
      # @param  *args [Array] The parameters to the association method call
      #
      # @raise [ArgumentError] If the provided arguments can't be used
      #
      def initialize(klass, *args)
        # Set the owner class which is provided directly
        @owner_class = klass
        # If the owner is a subclass of ApiResource::Base then try to
        # load the resource definition (< tests for subclass apparently)
        if @owner_class < ApiResource::Base
          @owner_class.load_resource_definition
        end
        # Get out the options
        options = args.extract_options!
        options = options.with_indifferent_access

        # Fail if nothing is provided for args or there is more than one
        # thing but options are provided also (Enforces that options can
        # only apply to associationds defined one at a time)
        if args.length == 0 || (args.length > 1 && options.present?)
          raise ArgumentError.new(
            'Invalid arguments provided to association definition'
          )
        end

        @association_name = args.first.to_sym
        # Use the class name if it is provided
        name = self.construct_association_class_name(@association_name)
        @association_class_name = (options[:class_name] || name).to_s
        # Use the foreign key if it is provided
        key = self.construct_foreign_key(
          @owner_class.name, @association_class_name
        )
        @foreign_key = (options[:foreign_key] || key).to_sym
        # Set the foreign key method based on the association name
        @foreign_key_method = self.construct_foreign_key_method(
          @association_name
        )
      end

      #
      # Returns the class that should be instantiated
      # for this association.
      #
      # @raise [AssociationClassNotFound] Error when it cannot find the provided class
      #
      # @return [Class] Some kind of class object
      def association_class
        const = ApiResource.lookup_constant(
          self.owner_class,
          self.association_class_name
        )

        unless const.present?
          raise AssociationClassNotFound.new(
            "Could not find class #{self.association_class_name}"
          )
        end

        return const
      end

      #
      # Builds an association proxy object for this association
      # owned by the provided owner object
      #
      # @param  owner [Object]
      #
      # @return [AssociationProxy]
      def association_proxy(owner)
        raise NotImplementedError.new(
          'Must define association_proxy in a subclass'
        )
      end

      #
      # Returns the type of this association as a symbol.
      # :has_many, :belongs_to, etc.
      #
      # @return [Symbol]
      def association_type
        self.class
          .name
          .demodulize
          .gsub(/Builder$/, '')
          .underscore
          .to_sym
      end

      #
      # Builds a module with the necessary methods for this
      # association and returns it.  It can then be included
      # in the owner_class to provide the proper methods
      #
      # @return [Module]
      def generated_methods_module
        return @generated_methods_module if @generated_methods_module
        mod = Module.new
        # Need local variables for scope reasons
        association_name = self.association_name
        foreign_key = self.foreign_key_method
        # The context of these methods will be an instance of
        # owner_class, they just need to deal with caching the proxy
        # objects somewhere
        mod.module_eval <<-EOM, __FILE__, __LINE__ + 1
          def #{association_name}
            read_association(:#{association_name})
          end

          def #{association_name}=(val)
            write_association(:#{association_name}, val)
          end

          def #{foreign_key}
            self.#{association_name}.read_foreign_key
          end

          def #{foreign_key}=(val)
            self.#{association_name}.write_foreign_key(val)
          end
        EOM
        @generated_methods_module = mod
      end

      protected

        #
        # Builds the class name that will be instantiated for the
        # association objects
        #
        # @param  assoc_name [Symbol]
        #
        # @return [String] A class name for this association
        def construct_association_class_name(assoc_name)
          assoc_name.to_s.classify
        end

        #
        # Builds the foreign key field name for this association
        #
        # @param  owner_class_name [String]
        # @param  assoc_class_name [String]
        #
        # @return [Symbol] The name of the foreign key
        def construct_foreign_key(owner_class_name, assoc_class_name)
          owner_class_name.foreign_key.to_sym
        end

        #
        # Builds the name of the foreign key method that will
        # be defined on the owner clas
        #
        # @param  assoc_name [Symbol]
        #
        # @return [Symbol] The name of the foreign key method
        # for the owner class
        def construct_foreign_key_method(assoc_name)
          assoc_name.to_s.foreign_key.to_sym
        end

    end

  end

end