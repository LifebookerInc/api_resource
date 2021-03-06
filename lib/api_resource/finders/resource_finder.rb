module ApiResource

  module Finders

    class ResourceFinder < AbstractFinder

      # this is a little bit simpler, it's always a collection and does
      # not require a remote path
      def load
        begin
          return [] if self.response.blank?

          @loaded = true

          if self.response.is_a?(Array)
            @internal_object = self.klass.instantiate_collection(
              self.response
            )
          else
            @internal_object = [
              self.klass.instantiate_record(self.response)
            ]
          end

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


          # Removed to mirror ActiveRecord
          # e.g. LifebookerClient::Provider.find([1])
          #
          # # looks hacky, but we want to return only a single
          # # object in case of a find call.
          # if @internal_object.count == 1 && self.build_load_path =~ /(&|\?)find/
          #   @internal_object = @internal_object.first
          # end

          return @internal_object
        rescue ApiResource::ResourceNotFound
          nil
        end
        @internal_object
      end

      protected


        # Find every resource
        def build_load_path
          prefix_opts, query_opts = self.klass.split_options(
            self.condition.to_hash
          )
          self.klass.collection_path(prefix_opts, query_opts)
        end

    end

  end

end
