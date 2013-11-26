module ApiResource

	module Finders

		class MultiObjectAssociationFinder < AbstractFinder

			# If they pass in the internal object just skip the first
			# step and apply the includes
			def initialize(klass, condition, internal_object = nil)
				super(klass, condition)

				@internal_object = internal_object
			end

			def load
				# otherwise just instantiate the record
				unless self.condition.remote_path
					raise "Tried to load association without a remote path"
				end

				return [] if self.response.blank?

				@internal_object ||= self.klass.instantiate_collection(
					Array.wrap(self.response)
				)

				@loaded = true

				id_hash = self.condition.included_objects.inject({}) do |accum, assoc|
					accum[assoc] = @internal_object.collect do |obj|
						obj.send(obj.class.association_foreign_key_field(assoc))
					end

					accum[assoc].flatten!
					accum[assoc].uniq!
					accum
				end

				included_objects = self.load_includes(id_hash)

				self.apply_includes(@internal_object, included_objects)

				return @internal_object
			end
		end

	end

end