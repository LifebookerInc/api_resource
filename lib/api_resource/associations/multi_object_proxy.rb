require 'api_resource/associations/association_proxy'

module ApiResource
  
  module Associations
   
      class MultiObjectProxy < AssociationProxy

        include Enumerable

        def all
          self.internal_object
        end

        def each(*args, &block)
          self.internal_object.each(*args, &block)
        end

        def serializable_hash(options)
          self.internal_object.collect{|obj| obj.serializable_hash(options) }
        end

        # force a load when calling this method
        def internal_object
          @internal_object ||= self.load_scope_with_options(:all, {})
        end
        
        def internal_object=(contents)
          return @internal_object = contents if contents.all?{|o| o.is_a?(self.klass)}
          return load(contents)
        end

        protected
        def load_scope_with_options(scope, options)
          scope = self.loaded_hash_key(scope.to_s, options)
          return [] if self.remote_path.blank?
          unless self.loaded[scope]
            self.times_loaded += 1
            self.loaded[scope] = self.klass.connection.get("#{self.remote_path}.#{self.klass.format.extension}?#{options.to_query}")
          end
          self.loaded[scope].collect{|item| self.klass.new(item)}
        end

        def load(contents)
          @internal_object = [] and return nil if contents.blank?
          if contents.is_a?(Array) && contents.first.is_a?(Hash) && contents.first[self.class.remote_path_element]
            settings = contents.slice!(0).with_indifferent_access
          end

          settings = contents.with_indifferent_access if contents.is_a?(Hash)
          settings ||= {}.with_indifferent_access

          raise "Invalid response for multi object relationship: #{contents}" unless settings[self.class.remote_path_element] || contents.is_a?(Array)
          self.remote_path = settings.delete(self.class.remote_path_element)

          settings.each do |key, value|
            raise "Expected the scope #{key} to point to a hash, to #{value}" unless value.is_a?(Hash)
            self.instance_eval <<-EOE, __FILE__, __LINE__ + 1
              def #{key}(opts = {})
                ApiResource::Associations::RelationScope.new(self, :#{key}, opts)
              end
            EOE
            self.scopes[key.to_s] = value
          end

          # Create the internal object
          @internal_object = contents.is_a?(Array) ? contents.collect{|item| self.klass.new(item)} : nil
        end
      end
    
  end
  
end