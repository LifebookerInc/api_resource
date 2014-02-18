module ApiResource

  #
  # Module containing the behavior for defining and
  # querying information about scopes
  #
  # @author [ejlangev]
  #
  module Scopes

    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :AbstractScope
    autoload :DefaultScope
    autoload :OptionalArgScope
    autoload :VariableArgScope

    #
    # Class to raise when trying to define a scope that already exists
    #
    # @author [ejlangev]
    #
    class DuplicateScope < ApiResource::Error
    end

    #
    # Class to raise when calling scopes with invalid arguments
    #
    # @author [ejlangev]
    #
    class InvalidArgument < ApiResource::Error
    end

    #
    # Class to raise when the definition of a scope is invalid
    #
    # @author [ejlangev]
    #
    class InvalidDefinition < ApiResource::Error
    end

    module ClassMethods

      #
      # Takes a hash of arguments and applies scopes to the
      # given base
      #
      # @param  params [Hash] The parameters to turn into scopes
      # @param  base = self [Object] An object to use as the basis
      # for the scopes
      #
      # @return [ApiResource::Condition] A condition object representing
      # adding all scopes from params to base
      def add_scopes(params, base = self)
      end

      #
      # Defines a group of scopes using the scope method
      #
      # @param  scopes [Hash] Keys are scope names, values are
      # scope definition
      #
      # @return [True] Always true
      def define_scopes(scopes)
        scopes.each_pair do |name, definition|
          scope(name, definition)
        end

        true
      end

      #
      # Defines a scope on the class this is included in
      #
      # @param  scope_name [Symbol] Name of the scope to define
      # @param  scope_definition [Hash] Attributes of the scope
      #
      # @raise [ApiResource::Scopes::DuplicateScope] Error if you try to
      # redefine a scope
      #
      # @return [Boolean] Always true
      def scope(scope_name, scope_definition)
        if scopes[scope_name].present?
          raise DuplicateScope.new(
            "Cannot redefined existing scope #{scope_name}"
          )
        end

        self.scopes[scope_name] = AbstractScope.factory(
          scope_name,
          scope_definition
        )
        # If this didn't raise an error then we define a method
        # on this class for the scope
        self.define_scope_method(
          scope_name,
          self.scopes[scope_name]
        )
        true
      end

      #
      # Check if a symbol is a defined scope
      #
      # @param  scope [Symbol] The name to search for
      #
      # @return [Boolean] True if scope is the name of an actual scope
      def scope?(scope)
        # TODO: Change this to be .present?
        !self.lookup_scope(scope).nil?
      end

      #
      # Returns the scope definition object
      #
      # @param  scope [Symbol] The name of the scope
      #
      # @return [ApiResource::Scopes::AbstractScope]
      def scope_definition(scope)
        self.lookup_scope(scope)
      end

      protected

        #
        # Defines the proper class method for this scope
        #
        # @param  name [Symbol] The name of the scope
        # @param  definition [ApiResource::Scopes::AbstractScope]
        #
        # @return [Boolean] Always true
        def define_scope_method(name, definition)
          # This creates the methods that can be
          # called to access the scopes and produce
          # condition objects
          define_singleton_method name do |*args|
            self.lookup_scope(name)
                .apply(self, *args)
          end
        end

        #
        # Looks up a scope by name on this class and its ancestors
        # by default
        #
        # @param  scope [Symbol] The name of the scope to look up
        # @param  include_ancestors = true [Boolean] Whether or not
        # to include ancestors in the lookup
        #
        # @return [ApiResource::Scopes::AbstractScope] The scope object
        # if it exists
        def lookup_scope(scope, include_ancestors = true)
          # Return nil if this is ApiResource::Base (that is the top of
          # the hierarchy)
          return nil if self == ApiResource::Base
          # Lookup the scopes on this classes hash of scopes
          result = self.scopes[scope]
          # If the result is not nil then return it
          return result if result

          if include_ancestors
            # If we are including ancestors just return the result
            # of looking up the scope on them
            return self.superclass.lookup_scope(scope)
          end
          # If we found nothing then retur nil
          nil
        end

        #
        # Wrapper method for the hash of scopes that maps
        # the symbol scope name to the value scope object
        #
        # @return [Hash]
        def scopes
          @scopes ||= Hash.new
        end

    end

    #
    # Delegates to the equivalent class method
    #
    # @param  scope [Symbol] The name of the scope
    #
    # @return [Boolean] True if the scope exists
    def scope?(scope)
      self.class.scope?(scope.to_sym)
    end

    #
    # Returns the scope definition object by delegating
    # to the equivalent class method
    #
    # @param  scope [Symbol] The name of the scope
    #
    # @return [ApiResource::Scopes::AbstractScope]
    def scope_definition(scope)
      self.class.scope_definition(scope)
    end

  end

end
