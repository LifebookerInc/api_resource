module ApiResource

	module Conditions

		class IncludeCondition < AbstractCondition

			def initialize(klass, incs)
				super({}, klass)
				@included_objects = Array.wrap(incs)
			end

		end

	end

end