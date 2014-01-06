module ApiResource

  module Conditions

    #
    # Class to handle pagination params, passing
    # of pagination params along to the server, and the
    # retrieval of the headers from the response
    #
    # @author [dlangevin]
    #
    class WhereCondition < AbstractCondition
      def initialize(klass, opts)
        super(opts, klass)
      end

    end
  end
end