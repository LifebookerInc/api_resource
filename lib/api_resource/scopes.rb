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
                if arg_types[i] == :req || args[i].present?
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
