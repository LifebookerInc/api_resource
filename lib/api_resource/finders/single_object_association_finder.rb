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

        # check our response
        return nil if self.response.blank?

        # get our internal object
        @internal_object ||= begin
          if self.response.is_a?(Array)
            self.klass.instantiate_record(self.response.first)
          else
            self.klass.instantiate_record(self.response)
          end
        end

        # mark us as loaded
        @loaded = true

        # now that the object is loaded, resolve the includes
        id_hash = self.condition.included_objects.inject({}) do |hash, assoc|
          hash[assoc] = Array.wrap(
            @internal_object.send(
              @internal_object.class.association_foreign_key_field(assoc)
            )
          )
          hash
        end

        # apply our includes
        included_objects = self.load_includes(id_hash)
        self.apply_includes(@internal_object, included_objects)

        return @internal_object
      end

    end

  end

end