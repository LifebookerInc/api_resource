module ApiResource
  
  module Associations
   
      class MultiObjectProxy < AssociationProxy

        include Enumerable

        # override the constructor to set data to nil by 
        # default
        def initialize(klass, owner, data = nil)
          super
        end

        def all
          self.internal_object
        end

        def collection?
          true
        end

        def each(*args, &block)
          self.internal_object.each(*args, &block)
        end
        
        def internal_object
          @internal_object ||= begin
            if self.remote_path.present?
              self.load
            else
              []
            end
          end
        end

        def internal_object=(contents)
          # if we were passed in a service uri, stop here
          # but if we have a service uri already then don't overwrite
          unless self.remote_path.present?
            return true if self.set_remote_path(contents)
          end

          if contents.try(:first).is_a?(self.klass)
            @loaded = true
            return @internal_object = contents
          elsif contents.instance_of?(self.class)
            @loaded = true
            return @internal_object = contents.internal_object
          elsif contents.is_a?(Array)
            @loaded = true
            return @internal_object = self.klass.instantiate_collection(
              contents
            )
          # we have only provided the resource definition
          elsif contents.nil?
            return @internal_object = nil
          else
            raise ArgumentError.new(
              "#{contents} must be a #{self.klass}, #{self.class}, " + 
              "Array or nil"
            )
          end
        end

        def ==(other)
          return false if self.class != other.class
          if self.internal_object.is_a?(Array)
            self.internal_object.sort.each_with_index do |elem, i|
              return false if other.internal_object.sort[i].attributes != elem.attributes
            end
          end
          return true
        end

        def serializable_hash(options)
          self.internal_object.collect{|obj| obj.serializable_hash(options) }
        end

        protected

        def to_condition
          obj = nil
          obj = self.internal_object if self.loaded?
          ApiResource::Conditions::MultiObjectAssociationCondition.new(self.klass, self.remote_path, obj)
        end

        def load(opts = {})
          res = self.to_condition.load
          @loaded = true
          res
        end

        def set_remote_path(opts)
         if opts.is_a?(Array) && opts.first.is_a?(Hash)
            if opts.first.symbolize_keys[self.class.remote_path_element.to_sym]
              service_uri_el = opts.shift
            else
              service_uri_el = {}
            end
          elsif opts.is_a?(Hash)
            service_uri_el = opts
          else
            service_uri_el = {}
          end

          @remote_path = service_uri_el.symbolize_keys.delete(
            self.class.remote_path_element.to_sym
          )

          return @remote_path.present?
        end

      end
    
  end
  
end