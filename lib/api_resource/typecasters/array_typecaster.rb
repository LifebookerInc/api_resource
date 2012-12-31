module ApiResource

  module Typecast

    module ArrayTypecaster

      def self.from_api(value)
        return Array.wrap(value)
      end

      def self.to_api(value)
        return Array.wrap(value)
      end

    end

  end

end
