module ApiResource
  module Associations
    class BelongsToRemoteObjectProxy < SingleObjectProxy

      # attr_reader :foreign_key


      # # sets some defaults for the foreign key name for this association
      # def self.define_association_as_attribute(klass, assoc_name, opts = {})
      #   opts["foreign_key"] = self.foreign_key_name(assoc_name)
      #   super(klass, assoc_name, opts)
      # end

      # # constructor
      # def initialize(klass, owner, opts = {})
      #   super

      #   @foreign_key = opts["foreign_key"] || @klass.to_s.foreign_key
      #   # now if we have an owner and a foreign key, we set
      #   # the data up to load
      #   if key = owner.send(self.foreign_key)
      #     self.remote_path =  self.klass.element_path(key)
      #   end
      # end
    end
  end
end