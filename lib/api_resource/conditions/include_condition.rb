module ApiResource

	module Conditions

		class IncludeCondition < AbstractCondition

      #
      # Constructor
      #
      # @param  klass [Class] Finder
      # @param  incs [Array<Symbol>, Symbol] Associations to include
      #
      def initialize(klass, incs)
				super({}, klass)
				@included_objects = Array.wrap(incs)
			end

		end

	end

end