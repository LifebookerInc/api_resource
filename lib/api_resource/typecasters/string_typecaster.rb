module ApiResource

  module Typecast

    module StringTypecaster

      def self.from_api(value)
        return value.to_s
      end

      def self.to_api(value)
        return value
      end

    end

  end

end
