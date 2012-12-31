module ApiResource
  
  module Associations
    
    class SingleObjectProxy < AssociationProxy

      def serializable_hash(options = {})
        return if self.internal_object.nil?
        self.internal_object.serializable_hash(options)
      end

      def internal_object
        unless instance_variable_defined?(:@internal_object)
          if self.remote_path.present?
            instance_variable_set(:@internal_object, self.load)
          else
            instance_variable_set(:@internal_object, nil)
          end
        end
        instance_variable_get(:@internal_object)
      end
      
      def internal_object=(contents)
        if contents.is_a?(self.klass) || contents.nil?
          return @internal_object = contents 
        elsif contents.is_a?(self.class)
          return @internal_object = contents.internal_object
        # a Hash may be attributes and/or a service_uri
        elsif contents.is_a?(Hash) 
          contents = contents.symbolize_keys
          @remote_path = contents.delete(
            self.class.remote_path_element.to_sym
          )
          if contents.present?
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
        ApiResource::Conditions::SingleObjectAssociationCondition.new(self.klass, self.remote_path)
      end

      # Should make a proper conditions object and call find on it
      def load(opts = {})
        @loaded = true
        @internal_object = self.to_condition.find
      end

      
    end
    
  end
  
end
