module ApiResource

  module Finders

    class SingleFinder < AbstractFinder

      def load
        return nil if self.response.blank?

        @loaded = true

        @internal_object = self.klass.instantiate_record(self.response)
        # now that the object is loaded, resolve the includes
        id_hash = self.condition.included_objects.inject({}) do |hash, assoc|
          hash[assoc] = Array.wrap(
            @internal_object.send(
              @internal_object.class.association_foreign_key_field(assoc)
            )
          )
          hash
        end

        included_objects = self.load_includes(id_hash)

        self.apply_includes(@internal_object, included_objects)

        return @internal_object
      end

      protected

      def build_load_path
        if self.condition.to_hash["id"].blank?
          raise "Invalid evaluation of a SingleFinder without an ID"
        end

        args = self.condition.to_hash
        id = args.delete("id")

        prefix_opts, query_opts = self.klass.split_options(args)
        self.klass.element_path(id, prefix_opts, query_opts)

      end

    end

  end

end