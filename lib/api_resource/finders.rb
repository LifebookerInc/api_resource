module ApiResource

	module Finders

		extend ActiveSupport::Concern
		extend ActiveSupport::Autoload

		autoload :AbstractFinder
		autoload :ResourceFinder
		autoload :SingleObjectAssociationFinder
		autoload :MultiObjectAssociationFinder

		module ClassMethods

   	# This decides which finder method to call. 
      # It accepts arguments of the form "scope", "options={}"
      # where options can be standard rails options or :expires_in. 
      # If :expires_in is set, it caches it for expires_in seconds.
      def find(*arguments)

        # make sure we have class data before loading
        self.load_resource_definition

        scope   = arguments.slice!(0)
        options = arguments.slice!(0) || {}
        
        expiry = options.delete(:expires_in) || ApiResource::Base.ttl || 0
        ApiResource.with_ttl(expiry.to_f) do
          case scope
            when :all   then find_every(options)
            when :first then find_every(options).first
            when :last  then find_every(options).last
            when :one   then find_one(options)
            else             find_single(scope, options)
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

      private

        # Find every resource
        def find_every(options)
          begin
            case from = options[:from]
            when Symbol
              instantiate_collection(get(from, options[:params]))
            when String
              path = "#{from}#{query_string(options[:params])}"
              instantiate_collection(connection.get(path, headers) || [])
            else
              prefix_options, query_options = split_options(options[:params])
              path = collection_path(prefix_options, query_options)
              instantiate_collection( (connection.get(path, headers) || []))
            end
          rescue ApiResource::ResourceNotFound
            # Swallowing ResourceNotFound exceptions and return nil - as per
            # ActiveRecord.
            nil
          end
        end

        # Find a single resource from a one-off URL
        def find_one(options)
          case from = options[:from]
          when Symbol
            instantiate_record(get(from, options[:params]))
          when String
            path = "#{from}#{query_string(options[:params])}"
            instantiate_record(connection.get(path, headers))
          end
        end

        # Find a single resource from the default URL
        def find_single(scope, options)
          prefix_options, query_options = split_options(options[:params])
          path = element_path(scope, prefix_options, query_options)
          instantiate_record(connection.get(path, headers))
        end

		end 
	end

end