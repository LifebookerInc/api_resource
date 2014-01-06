module ApiResource

	module Conditions

		extend ActiveSupport::Autoload
		extend ActiveSupport::Concern

		autoload :AbstractCondition
		autoload :AssociationCondition
		autoload :IncludeCondition
		autoload :MultiObjectAssociationCondition
		autoload :PaginationCondition
		autoload :SingleObjectAssociationCondition
		autoload :ScopeCondition
		autoload :WhereCondition

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

			def paginate(opts = {})
				self.load_resource_definition

				# Everything looks good so just create the scope
				ApiResource::Conditions::PaginationCondition.new(self, opts)

			end

			def where(opts = {})
				self.load_resource_definition

				ApiResource::Conditions::WhereCondition.new(self, opts)
			end

		end

	end


end