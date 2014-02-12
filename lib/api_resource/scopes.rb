module ApiResource

  #
  # Module containing the behavior for scopes
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
        self.scopes[scope_name] = AbstractScope.factory(
          scope_name,
          scope_definition
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




      # TODO: calling these methods should force loading of the resource definition
      def old_scopes
        return self.related_objects[:scopes]
      end

      def old_scope?(name)
        self.related_objects[:scopes].has_key?(name.to_sym)
      end

      def old_scope_attributes(name)
        raise "No such scope #{name}" unless self.scope?(name)
        self.related_objects[:scopes][name.to_sym]
      end

      # Called by base.rb
      # @param scope_name is the scope_name of the scope from the json
      # e.g. paged
      #
      # @param scope_definition is always a hash with the arguments for the scope
      # e.g. {:page => "req", "per_page" => "opt"}
      def old_scope(scope_name, scope_definition)

        unless scope_definition.is_a?(Hash)
          raise ArgumentError, "Expecting an attributes hash given #{scope_definition.inspect}"
        end

        self.related_objects[:scopes][scope_name.to_sym] = scope_definition

        self.class_eval do

          define_singleton_method(scope_name) do |*args|

            arg_names = scope_definition.keys
            arg_types = scope_definition.values

            finder_opts = {
              scope_name => {}
            }

            arg_names.each_with_index do |arg_name, i|

              # If we are dealing with a scope with multiple args
              if arg_types[i] == :rest
                finder_opts[scope_name][arg_name] =
                  args.slice(i, args.count)
              # Else we are only dealing with a single argument
              else
                if arg_types[i] == :req || (i < args.count)
                  finder_opts[scope_name][arg_name] = args[i]
                end
              end
            end

            # if we have nothing at this point we should just pass 'true'
            if finder_opts[scope_name] == {}
              finder_opts[scope_name] = true
            end

            ApiResource::Conditions::ScopeCondition.new(finder_opts, self)

          end
        end
      end

      #
      # Apply scopes from params based on our resource
      # definition
      #
      def old_add_scopes(params, base = self)
        # scopes are stored as strings but we want to allow
        params = params.with_indifferent_access
        base = self.add_static_scopes(params, base)
        return self.add_dynamic_scopes(params, base)
      end

      protected


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

      def old_add_static_scopes(params, base)
        self.static_scopes.each do |name|
          if params[name].present?
            base = base.send(name)
          end
        end
        return base
      end

      def old_add_dynamic_scopes(params, base)
        self.dynamic_scopes.each_pair do |name, args|
          next if params[name].blank?
          caller_args = []
          args.each_pair do |subkey, type|
            if type == :req || params[name][subkey].present?
              caller_args << params[name][subkey]
            end
          end
          base = base.send(name, *caller_args)
        end
        return base
      end

      #
      # Wrapper method to define all scopes from the resource definition
      #
      # @return [Boolean] true
      def old_define_all_scopes
        if self.resource_definition["scopes"]
          self.resource_definition["scopes"].each_pair do |name, opts|
            self.scope(name, opts)
          end
        end
        true
      end

      def old_dynamic_scopes
        self.scopes.select { |name, args| args.present? }
      end

      def old_static_scopes
        self.scopes.select { |name, args| args.blank? }.keys
      end

    end

    def old_scopes
      return self.class.scopes
    end

    def old_scope?(name)
      return self.class.scope?(name)
    end

    def old_scope_attributes(name)
      return self.class.scope_attributes(name)
    end

  end
end
