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
        lb_logger.info{ "Loading resource definition. Arguments: #{arguments.inspect}" }
        self.load_resource_definition

        final_conditions = initialize_arguments!(arguments)

        # TODO: Make this into a class attribute properly (if it isn't already)
        # this is a little bit of a hack because options can sometimes be a Condition
        expiry = @expiry
        ApiResource.with_ttl(expiry.to_f) do
          if numeric_find
            if (single_find || empty_find) && (final_conditions.blank_conditions? || nested_find_only?(final_conditions))
              # If we have no conditions or they are only prefixes or
              # includes, and only one argument (not a word) then we
              # only have a single item to find.
              # e.g. Class.includes(:association).find(1)
              #      Class.find(1)
              final_cond = final_conditions.merge!(ApiResource::Conditions::ScopeCondition.new({:id => @scope}, self))
              ApiResource::Finders::SingleFinder.new(self, final_cond).load
            else
              # e.g. Class.scope(1).find(1)
              #      Class.includes(:association).find(1,2)
              #      Class.find(1,2)
              #      Class.active.find(1)
              fnd = final_conditions.merge!(ApiResource::Conditions::ScopeCondition.new({:find => {:ids => @scope}}, self))
              fnd.send(:all)
            end
          else
            # e.g. Class.scope(1).first
            #      Class.first
            new_condition = @scope == :all ? {} : {@scope => true}

            final_cond = final_conditions.merge!ApiResource::Conditions::ScopeCondition.new(new_condition, self)

            fnd = ApiResource::Finders::ResourceFinder.new(self, final_cond)
            fnd.send(@scope)
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

      protected

      def arg_ary
        if @scope.blank?
          lb_logger{ "@scope.blank?: true"}
          return :none
        elsif !@scope.is_a?(Array)
          lb_logger{ "!@scope.is_a?(Array): true"}
          return :single
        else
          lb_logger{ "multiple: true"}
          return :multiple
        end
      end

      def arg_type
        arg = Array.wrap(@scope).first

        case arg
          when :first, :last
            :bookend
          when :all
            :all_records
          else
            :number
        end
      end

      def empty_find
        arg_ary == :none
      end

      def numeric_find
        arg_type == :number
      end

      def single_find
        lb_logger{ "arg_ary: #{arg_ary}"}
        return arg_ary == :single
      end

      def initialize_arguments!(args)

        args = Array.wrap(args)

        # Conditions sometimes call find, passing themselves as the last arg.
        if args.last.is_a?(ApiResource::Conditions::AbstractCondition)
          cond = args.slice!(args.length - 1)
        else
          cond = nil
        end

        # Support options being passed in as a hash.
        options   = args.extract_options!
        if options.blank?
          options = nil
        end

        @expiry   = (options.is_a?(Hash) ? options.delete(:expires_in) : nil) || ApiResource::Base.ttl || 0

        final_conditions = combine_conditions(options, cond)

        # Remaining args are the scope.
        @scope    = args

        if Array.wrap(@scope).size == 1 && @scope.is_a?(Array)
          @scope = @scope.first
        end

        final_conditions
      end

      def combine_conditions(options, condition)
        # Convert options hash to scope condition.
        if options.is_a?(Hash)
          opts = options.with_indifferent_access.delete(:params) || options || {}
          options = ApiResource::Conditions::ScopeCondition.new(opts, self)
        end

        final_cond = ApiResource::Conditions::ScopeCondition.new({}, self)

        # Combine all combinations of conditions and options
        if condition
          if options
            final_cond = condition.merge!(options)
          else
            final_cond = condition
          end
        elsif options
          final_cond = options
        end

        final_cond
      end

      def nested_find_only?(conditions)
        if conditions.blank_conditions?
          return false
        else
          return conditions.conditions.include?(:foreign_key_id) &&
            conditions.conditions.size == 1
        end
      end

    end

	end

end