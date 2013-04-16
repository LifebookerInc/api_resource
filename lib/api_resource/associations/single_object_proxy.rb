module ApiResource
  
  module Associations
    
    class SingleObjectProxy < AssociationProxy

      def serializable_hash(options = {})
        return if self.internal_object.nil?
        self.internal_object.serializable_hash(options)
      end

      def collection?
        false
      end

      def internal_object
        @internal_object ||= begin
          if self.remote_path.present? && !self.loaded?
            self.load
          else
            nil
          end
        end
      end
      
      def internal_object=(contents)
        if contents.is_a?(self.klass) || contents.nil?
          @loaded = true
          return @internal_object = contents 
        elsif contents.is_a?(self.class)
          @loaded = true
          return @internal_object = contents.internal_object
        # a Hash may be attributes and/or a service_uri
        elsif contents.is_a?(Hash) 
          contents = contents.symbolize_keys
          @remote_path = contents.delete(
            self.class.remote_path_element.to_sym
          )
          if contents.present?
            @loaded = true
            return @internal_object = self.klass.instantiate_record(contents)
          end
        else
          raise ArgumentError.new(
            "#{contents} must be a #{self.klass}, a #{self.class} or a Hash"
          )
        end
      end
      
      def ==(other)
        return false if self.class != other.class
        return false if other.internal_object.attributes != self.internal_object.attributes
        return true
      end

      def hash
        self.id.hash
      end

      def eql?(other)
        return self == other
      end

      protected

      def to_condition
        obj = nil
        obj = self.internal_object if self.loaded?
        ApiResource::Conditions::SingleObjectAssociationCondition.new(
          self.klass, self.remote_path, obj
        )
      end

      # Should make a proper conditions object and call find on it
      # It MUST set loaded to true after calling load
      def load(opts = {})
        res = self.to_condition.load
        @loaded = true
        res
      end

      
    end
    
  end
  
end
