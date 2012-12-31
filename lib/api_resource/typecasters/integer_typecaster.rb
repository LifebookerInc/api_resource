module ApiResource

  module Typecast

    module IntegerTypecaster

      def self.from_api(value)
        return value.to_i if value.respond_to?(:to_i)
        # Special case so that true typecasts to 1
        return 1 if value.class == TrueClass
        return value.to_s.to_i
      end

      def self.to_api(value)
        value
      end

    end

  end

end
