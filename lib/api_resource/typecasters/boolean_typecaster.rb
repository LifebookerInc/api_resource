module ApiResource

  module Typecast

    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set

    module BooleanTypecaster

      def self.from_api(value)
        return nil if value.nil?
        TRUE_VALUES.include?(value)
      end

      def self.to_api(value)
        value
      end

    end

  end

end
