module ApiResource
  
  module Associations
   
    class AssociationProxy


      class_attribute :remote_path_element
      self.remote_path_element = :service_uri 

      attr_accessor :remote_path
      attr_reader :owner, :klass, :finder_opts

      # TODO: add the other load forcing methods here for collections
      delegate :[], :[]=, :<<, :first, :second, :last, :blank?, :nil?, 
        :include?, :push, :pop, :+, :concat, :flatten, :flatten!, :compact, 
        :compact!, :empty?, :fetch, :map, :reject, :reject!, :reverse, 
        :select, :select!, :size, :sort, :sort!, :uniq, :uniq!, :to_a, 
        :sample, :slice, :slice!, :count, :present?, 
        :to => :internal_object

      # define association methods on the class
      def self.define_association_as_attribute(klass, assoc_name, opts = {})

        id_method_name = self.foreign_key_name(assoc_name)
        associated_class = opts[:class_name] || assoc_name.to_s.classify
        
        klass.api_resource_generated_methods.module_eval <<-EOE, __FILE__, __LINE__ + 1
          def #{assoc_name}
            @attributes_cache[:#{assoc_name}] ||= begin
              instance = #{self}.new(#{associated_class}, self)
              if @attributes[:#{assoc_name}].present?
                instance.internal_object = @attributes[:#{assoc_name}]
              end
              instance
            end
          end
          def #{assoc_name}=(val, force = true)
            if !force
              #{assoc_name}_will_change!
            elsif self.#{assoc_name}.internal_object != val
              #{assoc_name}_will_change!
            end
            # This should not force a load
            self.#{assoc_name}.internal_object = val
          end

          def #{assoc_name}?
            self.#{assoc_name}.internal_object.present?
          end

          # writer is the same for everyone
          def #{id_method_name}=(val, force = false)
            unless @attributes_cache[:#{id_method_name}] == val
              #{id_method_name}_will_change!
            end
            @attributes_cache[:#{id_method_name}] = val
            write_attribute(:#{id_method_name}, val)
          end

        EOE
      end

      protected

      # return a foreign key name from an association
      def self.foreign_key_name(assoc_name)
        assoc_name.to_s.singularize.foreign_key
      end

      public

      def initialize(klass, owner, opts = {})

        # the base class for our scope, e.g. ApiResource::SomeClass
        @klass = klass.is_a?(String) ? klass.constantize : klass

        # load the resource definition
        @klass.load_resource_definition

        @owner = owner
        
        self.internal_object = opts
      end

      def ttl
        @ttl || 0
      end

      # Use this method to access the internal data, this guarantees that loading only occurs once per object
      def internal_object
        if instance_variable_defined?(:@internal_object)
          return instance_variable_get(:@internal_object)
        end
        instance_variable_set(:@internal_object, self.load)
      end

      # has the scope been loaded?
      def loaded?
        @loaded == true
      end

      def load_resource_definition
        self.klass.load_resource_definition
      end

      # unset all of our scope values and our internal object
      def reload
        @loaded = false
        if instance_variable_defined?(:@internal_object)
          remove_instance_variable(:@internal_object)
        end
        self
      end

      def expires_in(ttl)
        ApiResource::Decorators::CachingDecorator.new(self, ttl)
      end


      def includes(*args)
        self.to_condition.merge!(self.klass.includes(*args))
      end

      def ==(other)
         raise "Not Implemented: This method must be implemented in a subclass"
      end

      protected

        def method_missing(method, *args, &block)
          # If we are calling a scoped method that should be allowed
          if self.klass.scope?(method)
            cond = self.klass.send(method, *args, &block)
            self.to_condition.merge!(cond)
          else
            self.internal_object.send(method, *args, &block)
          end
        end

        # require our subclasses to implement a way to find records
        def load
          raise NotImplementedError.new("#{self.class} must implement #load")
        end

    end
    
  end
  
end