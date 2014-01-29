module ApiResource
  module Scopes

    extend ActiveSupport::Concern

    module ClassMethods
      # TODO: calling these methods should force loading of the resource definition
      def scopes
        self.reload_resource_definition
        return self.related_objects[:scopes]
      end

      def scope?(name)
        self.related_objects[:scopes].has_key?(name.to_sym)
      end

      def scope_attributes(name)
        raise "No such scope #{name}" unless self.scope?(name)
        self.related_objects[:scopes][name.to_sym]
      end

      # Called by base.rb
      # @param scope_name is the scope_name of the scope from the json
      # e.g. paged
      #
      # @param scope_definition is always a hash with the arguments for the scope
      # e.g. {:page => "req", "per_page" => "opt"}
      def scope(scope_name, scope_definition)

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
      def add_scopes(params, base = self)
        # scopes are stored as strings but we want to allow
        params = params.with_indifferent_access
        base = self.add_static_scopes(params, base)
        return self.add_dynamic_scopes(params, base)
      end

      protected

      def add_static_scopes(params, base)
        self.static_scopes.each do |name|
          if params[name].present?
            base = base.send(name)
          end
        end
        return base
      end

      #
      # Add our dynamic scopes based on a set of params
      #
      # @param  params [Hash] User-supplied params
      # @param  base [ApiResource::Conditions::AbstractCondition, Class] Base
      # Scope
      #
      # @return [ApiResource::Conditions::AbstractCondition] [description]
      def add_dynamic_scopes(params, base)
        self.dynamic_scopes.each_pair do |name, args|
          # make sure we have all required arguments
          next unless self.check_required_scope_args(args, params[name])

          # the args we will apply
          caller_args = []

          # iterate through our args and add them to an array to send to our
          # scope
          args.keys.each do |subkey|
            # we only apply things that are present or explicitly false
            if val = self.get_scope_arg_value(subkey, params[name][subkey])
              caller_args << val
            end
          end
          # call our scope with the supplied args
          base = base.send(name, *caller_args)
        end
        return base
      end

      #
      # Check if we have supplied all of the necessary
      # @param  scope [Hash] [Scope Definition
      # @param  params [Hash] [Supplied params]
      #
      # @return [Boolean] Validity
      def check_required_scope_args(scope, params)
        # make sure we have a hash and it has values
        return false unless params.is_a?(Hash) && params.present?
        # find required values
        required = scope.select{ |k,v| v.to_sym == :req }.keys
        # make sure we have all of the required values, we allow false
        required.all? { |key|
          params[key].present? || params[key] == false
        }
      end

      #
      # Wrapper method to define all scopes from the resource definition
      #
      # @return [Boolean] true
      def define_all_scopes
        if self.resource_definition["scopes"]
          self.resource_definition["scopes"].each_pair do |name, opts|
            self.scope(name, opts)
          end
        end
        true
      end

      #
      # Scopes that require arguments
      #
      # @return [Hash]
      def dynamic_scopes
        self.scopes.select { |name, args| args.present? }
      end

      #
      # Get the parsed/formatted arguments to send to the server
      #
      # @param  key [String, Symbol] Key name for the scope value
      # @param  value [String, Integer, Symbol] Value for the scope
      #
      # @return [String, Integer, Symbol, Date] Parsed/formatted value
      def get_scope_arg_value(key, value)
        # cast to string to avoid incorred blank? behavior for us
        return "false" if value == false
        # if we havea date field, try to parse, falling back to the original
        # value
        if key.to_s =~ /date/
          value = Date.parse(value) rescue value
        end
        # return the final value
        value
      end

      def static_scopes
        self.scopes.select { |name, args| args.blank? }.keys
      end

    end

    def scopes
      return self.class.scopes
    end

    def scope?(name)
      return self.class.scope?(name)
    end

    def scope_attributes(name)
      return self.class.scope_attributes(name)
    end

  end
end
