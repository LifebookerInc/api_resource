module ApiResource

  module Typecast

    module FloatTypecaster

      def self.from_api(value)
        return value.to_f if value.respond_to?(:to_f)
        # Special case for true to return 1.0
        return 1.0 if value.class == TrueClass
        return value.to_s.to_f
      end

      def self.to_api(value)
        value
      end

    end

  end

end
