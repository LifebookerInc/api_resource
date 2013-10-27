module ApiResource

  module Typecast

    # The unknown typecaster which does not modify the value of
    # the attribute in either direction.  Keeps the interface consistent
    # for unspecified typecasters
    #
    # @author [ejlangev]
    #
    module UnknownTypecaster

      #
      # Just returns what was passed in
      # @param  value [Object] The value to typecast
      #
      # @return [Object] An unmodified value
      def self.from_api(value)
        return value
      end

      #
      # Just returns what was passed in
      # @param  value [Object] The value to typecast
      #
      # @return [Object] An unmodified value
      def self.to_api(value)
        return value
      end

    end
  end
end