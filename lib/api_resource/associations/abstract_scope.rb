module ApiResource

  module Associations

    class AbstractScope

      attr_reader :klass, :finder_opts

      include Enumerable

      def initialize(klass, finder_opts = {})

        # the base class for our scope, e.g. ApiResource::SomeClass
        @klass = klass.is_a?(String) ? klass.constantize : klass

        # load the resource definition
        @klass.load_resource_definition

        # the parent scope - for composing all of the finder options
        @parent = finder_opts.delete(:__parent)

        @finder_opts = finder_opts
        
        # Where subscope is any scope down the chain, e.g. active.*future*
        @klass.scopes.each do |scope_name, scope_definition|
          self.define_subscope(scope_name, scope_definition)
        end
      end

      def ttl
        @ttl || 0
      end

      def each(*args, &block)
        self.internal_object.each(*args, &block)
      end

      # Use this method to access the internal data, this guarantees that loading only occurs once per object
      def internal_object
        if instance_variable_defined?(:@internal_object)
          return instance_variable_get(:@internal_object)
        end
        instance_variable_set(:@internal_object, self.load)
      end
      alias_method :all, :internal_object

      # has the scope been loaded?
      def loaded?
        @loaded == true
      end

      def load_resource_definition
        self.klass.load_resource_definition
      end

      def scopes
        @scopes ||= HashWithIndifferentAccess.new
      end

      def scope?(scp)
        self.scopes.key?(scp.to_s)
      end

      # def current_scope
      #   ActiveSupport::StringInquirer.new(@current_scope.join("_and_").concat("_scope"))
      # end

      def to_hash
        self.parent_hash.merge(self.finder_opts)
      end

      # takes empty hashes and replaces them with true so that to_query doesn't strip them out
      def to_query_safe_hash(hash)
        hash.each_pair do |k, v|
          hash[k] = to_query_safe_hash(v) if v.is_a?(Hash)
          hash[k] = true if v == {}
        end
        return hash
      end

       # gets the current hash and calls to_query on it
      def to_query
        #We need to add the unescape because to_query breaks on nested arrays
        CGI.unescape(to_query_safe_hash(self.to_hash).to_query)
      end

      # unset all of our scope values and our internal object
      def reload
        (self.scopes.keys + [:internal_object]).each do |ivar|
          if instance_variable_defined?("@#{ivar}")
            remove_instance_variable("@#{ivar}")
          end
        end
        @loaded = false
        self
      end

      def to_s
        self.internal_object.to_s
      end

      def inspect
        self.internal_object.inspect
      end

      def blank?
        self.internal_object.blank?
      end
      alias_method :empty?, :blank?

      def present?
        self.internal_object.present?
      end

      def expires_in(ttl)
        ApiResource::Decorators::CachingDecorator.new(self, ttl)
      end

      protected

        # scope_name => e.g. paged
        # scope_definition => e.g. {:page => "req", "per_page" => "opt"}

        def define_subscope(scope_name, scope_definition)

          self.scopes[scope_name] = scope_definition

          self.class_eval do

            define_method(scope_name) do |*args|
            
              unless instance_variable_defined?("@#{scope_name}")
               
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

                instance_variable_set(
                  "@#{scope_name}",
                  self.get_subscope_instance(finder_opts)
                )
              end
              instance_variable_get("@#{scope_name}")
            end
          end
        end

        def get_subscope_instance(finder_opts)
          ApiResource::Associations::Scope.new(
            self, finder_opts.merge(:__parent => self)
          )
        end

        def method_missing(method, *args, &block)
          self.internal_object.send(method, *args, &block)
        end

        # querystring hash from parent
        def parent_hash
          @parent ? @parent.to_hash : {}
        end

        # require our subclasses to implement a way to find records
        def load
          raise NotImplementedError.new("#{self.class} must implement #load")
        end
        
        # make sure we have a valid scope
        def check_scope(scp)
          raise ArgumentError, "Unknown scope #{scp}" unless self.scope?(scp.to_s)
        end
    end

  end

end
