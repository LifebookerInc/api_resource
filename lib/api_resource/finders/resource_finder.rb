module ApiResource

	module Finders

		class ResourceFinder < AbstractFinder

			# this is a little bit simpler, it's always a collection and does
			# not require a remote path
			def find
				@loaded = true
				@internal_object = self.klass.find(:all, self.condition.to_hash)
				return [] if @internal_object.blank?

				id_hash = self.condition.included_objects.inject({}) do |accum, assoc|
					accum[assoc] = @internal_object.collect do |obj|
						obj.send(self.klass.association_foreign_key_field(assoc))
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