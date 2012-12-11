require 'api_resource/associations/association_scope'

module ApiResource
  
  module Associations
   
      class MultiObjectProxy < AssociationScope

        include Enumerable

        # override the constructor to set data to nil by 
        # default
        def initialize(klass, owner, data = nil)
          super
        end

        def all
          self.internal_object
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
          return true if self.set_remote_path_and_scopes(contents)

          if contents.try(:first).is_a?(self.klass)
            return @internal_object = contents 
          elsif contents.instance_of?(self.class)
            return @internal_object = contents.internal_object
          elsif contents.is_a?(Array)
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

        def load(opts = {})
          data = self.klass.connection.get(self.build_load_path(opts))
          @loaded = true
          return [] if data.blank?
          return self.klass.instantiate_collection(data)
        end

        protected

        # set up the remote path from a set of options passed in
        def set_remote_path_and_scopes(opts)
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

          service_uri_el.each_pair do |scope_name, scope_def|
            self.define_subscope(scope_name, scope_def)
          end

          return @remote_path.present?
        end

      end
    
  end
  
end