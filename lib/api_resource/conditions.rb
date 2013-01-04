module ApiResource

	module Conditions

		extend ActiveSupport::Autoload
		extend ActiveSupport::Concern

		autoload :AbstractCondition
		autoload :AssociationCondition
		autoload :SingleObjectAssociationCondition
		autoload :MultiObjectAssociationCondition
		autoload :IncludeCondition
		autoload :ScopeCondition

		module ClassMethods

			def includes(*args)

				self.load_resource_definition

				# everything in args must be an association
				args.each do |arg|
					unless self.association?(arg)
						raise ArgumentError, "Unknown association #{arg} to eager load"
					end
				end

				# Everything looks good so just create the scope
				ApiResource::Conditions::IncludeCondition.new(self, args)

			end

		end

	end


end