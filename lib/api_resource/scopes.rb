module ApiResource
  module Scopes

    extend ActiveSupport::Concern

    module ClassMethods
      # TODO: calling these methods should force loading of the resource definition
      def scopes
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

      def add_dynamic_scopes(params, base)
        self.dynamic_scopes.each_pair do |name, args|
          next if params[name].blank?
          ApiResource.logger.debug { "Applying scope: #{name}" }
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
      def define_all_scopes
        if self.resource_definition["scopes"]
          self.resource_definition["scopes"].each_pair do |name, opts|
            self.scope(name, opts)
          end
        end
        true
      end

      def dynamic_scopes
        self.scopes.select { |name, args| args.present? }
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
