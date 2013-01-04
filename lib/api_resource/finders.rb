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

        scope   = arguments.slice!(0)
        options = arguments.slice!(0) || {}
        cond    = arguments.slice!(0)

        # TODO: Make this into a class attribute properly (if it isn't already)
        # this is a little bit of a hack because options can sometimes be a Condition
        expiry = (options.is_a?(Hash) ? options.delete(:expires_in) : nil) || ApiResource::Base.ttl || 0
        ApiResource.with_ttl(expiry.to_f) do
          case scope
          when :all, :first, :last
            final_cond = ApiResource::Conditions::ScopeCondition.new({}, self)
            # we need new conditions here to take into account options, which could
            # either be a Condition object or a hash
            if options.is_a?(Hash)
              opts = options.with_indifferent_access.delete(:params) || options || {}
              final_cond = ApiResource::Conditions::ScopeCondition.new(opts, self)
              # cond may be nil
              unless cond == nil # THIS MUST BE == NOT nil?
                final_cond = cond.merge!(final_cond)
              end
            elsif options.is_a?(ApiResource::Conditions::AbstractCondition)
              final_cond = options
            end
            # now final cond contains all the conditions we should need to pass to the finder
            fnd = ApiResource::Finders::ResourceFinder.new(self, final_cond)
            fnd.send(scope)
          else
            # in this case scope is the id we want to find, and options should be a condition object or nil
            final_cond = ApiResource::Conditions::ScopeCondition.new({:id => scope}, self)
            if options.is_a?(ApiResource::Conditions::AbstractCondition)
              final_cond = options.merge!(final_cond)
            elsif options.is_a?(Hash)
              opts = options.with_indifferent_access.delete(:params) || options || {}
              final_cond = ApiResource::Conditions::ScopeCondition.new(opts, self).merge!(final_cond)
            end
            ApiResource::Finders::SingleFinder.new(self, final_cond).load
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