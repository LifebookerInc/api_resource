module ApiResource

	module Conditions

		class AssociationCondition < AbstractCondition

			def initialize(klass, service_uri, internal_object= nil)
				super({}, klass)

				@assocaiton = true
				@remote_path = service_uri
				@internal_object = internal_object
			end

		end

	end

end