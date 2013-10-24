module ApiResource

	module Finders

		extend ActiveSupport::Concern
		extend ActiveSupport::Autoload

		autoload :AbstractFinder
		autoload :ResourceFinder
    autoload :SingleFinder
		autoload :SingleObjectAssociationFinder
		autoload :MultiObjectAssociationFinder

		module ClassMethods

   	# This decides which finder method to call. 
      # It accepts arguments of the form "scope", "options={}"
      # where options can be standard rails options or :expires_in. 
      # If :expires_in is set, it caches it for expires_in seconds.

      # Need to support the following cases
      # => 1) Klass.find(1)
      # => 2) Klass.find(:all, :params => {a => b})
      # => 3) Klass.find(:first, :params => {a => b})
      # => 4) Klass.includes(:assoc).find(1)
      # => 5) Klass.active.find(1)
      # => 6) Klass.includes(:assoc).find(:all, a => b)
      def find(*arguments)
        # make sure we have class data before loading
        self.load_resource_definition

        # Conditions sometimes call find, passing themselves as the last arg.
        if arguments.last.is_a?(ApiResource::Conditions::AbstractCondition)
          cond  = arguments.slice!(arguments.length - 1) 
        else
          cond  = nil
        end

        # Support options being passed in as a hash.
        options = arguments.extract_options! || {}

        # Remaining arguments are the scope.
        scope   = arguments

        # TODO: Make this into a class attribute properly (if it isn't already)
        # this is a little bit of a hack because options can sometimes be a Condition
        expiry = (options.is_a?(Hash) ? options.delete(:expires_in) : nil) || ApiResource::Base.ttl || 0
        ApiResource.with_ttl(expiry.to_f) do

          # If we have a condition or options to process...
          if cond || options.present?

            # Convert options hash to scope condition.
            if options.is_a?(Hash)
              opts = options.with_indifferent_access.delete(:params) || options || {}
              options = ApiResource::Conditions::ScopeCondition.new(opts, self)
            end

            # Combine all combinations of conditions and options
            if cond
              if options
                final_cond = cond.merge!(options)
              else
                final_cond = cond
              end
            elsif options
              final_cond = options
            end

            # If we have one argument, it's either a word argument
            # like first, last, or all, or its a number.
            if Array.wrap(scope).size == 1
              scope = scope.first if scope.is_a?(Array)

              # Create the finder with the conditions, then call the scope.
              # e.g. Class.scope(1).first
              if [:all, :first, :last].include?(scope)
                fnd = ApiResource::Finders::ResourceFinder.new(self, final_cond)
                fnd.send(scope)

              # If we have no conditions or they are only prefixes or
              # includes,and only one argument (not a word) then we 
              # only have a single item to find.
              # e.g. Class.includes.find(1)
              elsif final_cond.blank_conditions? || final_cond.conditions.include?(:foreign_key_id)
                scope = scope.first if scope.is_a?(Array)
                final_cond = final_cond.merge!(ApiResource::Conditions::ScopeCondition.new({:id => scope}, self))

                ApiResource::Finders::SingleFinder.new(self, final_cond).load
              else

                # Otherwise we are chaining a find onto
                # the end of a set of conditions.
                # e.g. Class.scope(1).find(1)
                fnd = final_cond.merge!(ApiResource::Conditions::ScopeCondition.new({:find => {:ids => scope}}, self))
                fnd.send(:all)
              end

            else

              # We are searching for multiple ids.
              # e.g. Class.scope(1).find(1,2)
              fnd = final_cond.merge!(ApiResource::Conditions::ScopeCondition.new({:find => {:ids => scope}}, self))
              fnd.send(:all)
            end

          else

            # No conditions
            if Array.wrap(scope).size == 1
              scope = scope.first if scope.is_a?(Array)

              # We are calling first, last, or all on the class itself.
              # e.g. Class.first
              if [:all, :first, :last].include?(scope)
                final_cond = ApiResource::Conditions::ScopeCondition.new({scope => true}, self)

                fnd = ApiResource::Finders::ResourceFinder.new(self, final_cond)
                fnd.send(scope)
              else

                # We are performing a simple find of a single object
                # e.g. Class.find(1)
                scope = scope.first if scope.is_a?(Array)
                final_cond = ApiResource::Conditions::ScopeCondition.new({:id => scope}, self)

                ApiResource::Finders::SingleFinder.new(self, final_cond).load
              end

            else
              # We are performing a find on multiple objects
              # e.g. Class.find(1,2)
              ApiResource::Conditions::ScopeCondition.new({:find => {:ids => scope}}, self)
              fnd.send(:all)

            end

          end

        end
      end


      # A convenience wrapper for <tt>find(:first, *args)</tt>. You can pass
      # in all the same arguments to this method as you can to
      # <tt>find(:first)</tt>.
      def first(*args)
        find(:first, *args)
      end

      # A convenience wrapper for <tt>find(:last, *args)</tt>. You can pass
      # in all the same arguments to this method as you can to
      # <tt>find(:last)</tt>.
      def last(*args)
        find(:last, *args)
      end

      # This is an alias for find(:all).  You can pass in all the same
      # arguments to this method as you can to <tt>find(:all)</tt>
      def all(*args)
        find(:all, *args)
      end

       def instantiate_collection(collection)
        collection.collect{|record| 
          instantiate_record(record)
        }
      end

      def instantiate_record(record)
        self.load_resource_definition
        ret = self.allocate
        ret.instance_variable_set(
          :@attributes, record.with_indifferent_access
        )
        ret.instance_variable_set(
          :@attributes_cache, HashWithIndifferentAccess.new
        )
        ret
      end

		end 
	end

end