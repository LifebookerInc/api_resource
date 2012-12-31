module ApiResource

	module Conditions

		# Special class for passing into a finder object
		# just defines all the proper methods
		class SingleObjectAssociationCondition < AssociationCondition

			protected

			def instantiate_finder
				ApiResource::Finders::SingleObjectAssociationFinder.new(self.klass, self)
			end

		end

	end

end