module ApiResource

  module Conditions

    #
    # Simple class to represent a condition object that
    # places no restrictions on what is loaded
    #
    # @author [ejlangev]
    #
    class BlankCondition < WhereCondition

      def initialize
      end

    end

  end

end