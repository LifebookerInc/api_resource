module ApiResource

	module Conditions

		extend ActiveSupport::Autoload
		extend ActiveSupport::Concern

		autoload :AbstractCondition
		autoload :BlankCondition
		autoload :IncludeCondition
		autoload :PaginationCondition
		autoload :WhereCondition

		module ClassMethods

			#
			# Class level implementation of the includes method

			# @param  *args [Array<Symbol>] Array of symbols that
			# specify the names of the associations to include
			#
			# @return [ApiResource::Conditions::IncludeCondition]
			def includes(*args)
				self.load_resource_definition

				# everything in args must be an association
				args.each do |arg|
					unless self.association?(arg.to_sym)
						raise ApiResource::Associations::UnknownEagerLoadAssociation.new(
							"Unknown association #{arg} to eager load"
						)
					end
				end

				# Everything looks good so just create the scope
				ApiResource::Conditions::IncludeCondition.new(self, args)

			end

			#
			# Class level implementation of the paginate method

			# @param  opts = {} [Hash] Hash of arguments to paginate with
			#
			# @return [ApiResource::Conditions::PaginationCondition]
			def paginate(opts = {})
				self.load_resource_definition

				# Everything looks good so just create the scope
				ApiResource::Conditions::PaginationCondition.new(self, opts)

			end

			#
			# Class level implementation of the where method

			# @param  opts = {} [Hash] Arguments hash converted
			# directly into params
			#
			# @return [ApiResource::Conditions::WhereCondition]
			def where(opts = {})
				self.load_resource_definition

				ApiResource::Conditions::WhereCondition.new(self, opts)
			end

		end

	end


end