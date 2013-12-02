module ApiResource

  module Typecast

    module IntegerTypecaster

      def self.from_api(value)
        return 0 if value == false
        return 1 if value == true
        return nil if value.nil?
        return nil if value.is_a?(String) && value.blank?
        return value.to_i if value.respond_to?(:to_i)
        return value.to_s.to_i
      end

      def self.to_api(value)
        value
      end

    end

  end

end
