module ApiResource

	module Finders

		class MultiObjectAssociationFinder < AbstractFinder

			def find
				# otherwise just instantiate the record
				unless self.condition.remote_path
					raise "Tried to load association without a remote path"
				end

				data = self.klass.connection.get(self.build_load_path)
				@loaded = true
				return [] if data.blank?

				@internal_object = self.klass.instantiate_collection(data)

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