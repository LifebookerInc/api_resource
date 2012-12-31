module ApiResource

	module Conditions

		class AssociationCondition < AbstractCondition

			def initialize(klass, service_uri)
				super({}, klass)

				@assocaiton = true
				@remote_path = service_uri
			end

		end

	end

end