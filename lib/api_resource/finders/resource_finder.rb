module ApiResource

	module Finders

		class ResourceFinder < AbstractFinder

			# this is a little bit simpler, it's always a collection and does
			# not require a remote path
			def load
				begin
					@loaded = true
					@internal_object = self.klass.connection.get(self.build_load_path)
					return [] if @internal_object.blank?

					@internal_object = self.klass.instantiate_collection(@internal_object)

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
				rescue ApiResource::ResourceNotFound
					nil
				end
				@internal_object
			end

			protected


        # Find every resource
        def build_load_path
        	prefix_opts, query_opts = self.klass.split_options(self.condition.to_hash)
	        self.klass.collection_path(prefix_opts, query_opts)
        end

		end

	end

end