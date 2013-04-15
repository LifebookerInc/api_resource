module ApiResource

	module Conditions

		class MultiObjectAssociationCondition < AssociationCondition

			protected

			def instantiate_finder
				ApiResource::Finders::MultiObjectAssociationFinder.new(
          self.klass, self, @internal_object
        )
			end

		end

	end

end