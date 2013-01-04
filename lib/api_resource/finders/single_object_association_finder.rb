module ApiResource

	module Finders

		class SingleObjectAssociationFinder < AbstractFinder

			def initialize(klass, condition, internal_object = nil)
				super(klass, condition)

				@internal_object = internal_object
			end

			# since it is only a single object we can just load from
			# the service_uri and deal with includes
			def load
				# otherwise just instantiate the record
				unless self.condition.remote_path
					raise "Tried to load association without a remote path"
				end

				unless @internal_object
					data = self.klass.connection.get(self.build_load_path)
					
					return nil if data.blank?
					@internal_object = self.klass.instantiate_record(data)
				end

				@loaded = true
				# now that the object is loaded, resolve the includes
				id_hash = self.condition.included_objects.inject({}) do |accum, assoc|
					accum[assoc] = Array.wrap(
						@internal_object.send(
							@internal_object.class.association_foreign_key_field(assoc)
						)
					)
					accum
				end

				included_objects = self.load_includes(id_hash)

				self.apply_includes(@internal_object, included_objects)

				return @internal_object
			end

		end

	end

end