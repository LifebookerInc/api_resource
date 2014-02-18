module ApiResource

	module Conditions

		class ScopeCondition < AbstractCondition

      attr_reader :klass

      attr_reader :condition_hash

      def initialize(klass, condition_hash)
        @condition_hash = condition_hash.with_indifferent_access
        @klass = klass
        super(klass)
      end

      def conditions
        super.merge(@condition_hash)
      end

		end

	end

end