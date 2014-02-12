module ApiResource

  module Associations

      class MultiObjectProxy < AssociationProxy

        # All multi object proxies are enumerable
        include Enumerable

        #
        # Test if this proxy object wraps a collection
        #
        # @return [Boolean]
        def collection?
          true
        end

        #
        # Sets this association to an array of objects of the proper
        # type.  Sets the foreign keys on the new objects but does _NOT_
        # call save on them
        #
        # @param  vals [Array<ApiResource::Base>] The new association
        #
        # @return [Array<ApiResource::Base>] Returns whatever was passed in as
        # an array if it wasn't one already
        def assign(vals)
          vals = Array.wrap(vals)

          unless vals.all? { |v| v.is_a?(self.builder.association_class) }
            raise AssociationTypeMismatch.new(
              "Expected all instances of #{self.builder.association_class}, " +
              "got instance of other classes."
            )
          end

          super(vals)
          # Set the foreign keys properly
          @internal_object.each do |obj|
            obj.send(
              :write_attribute,
              self.builder.foreign_key,
              self.owner.read_attribute(:id)
            )
          end

          vals
        end

        private

          def construct_finder(condition)
            ApiResource::Finders::MultiObjectFinder.new(
              self.builder.association_class,
              condition
            )
          end

      #   include Enumerable

      #   def all
      #     self.internal_object
      #   end

      #   def collection?
      #     true
      #   end

      #   def each(*args, &block)
      #     self.internal_object.each(*args, &block)
      #   end

      #   def internal_object

      #     # if we don't have a remote path or any data so we set it to a
      #     # blank array
      #     if self.remote_path.blank? && @internal_object.blank?
      #       return @internal_object ||= []
      #     end

      #     # if we aren't loaded and we don't have data added load here
      #     if !self.loaded? && @internal_object.blank?
      #       @internal_object = self.load
      #     end
      #     @internal_object
      #   end

      #   def internal_object=(contents)
      #     # if we were passed in a service uri, stop here
      #     # but if we have a service uri already then don't overwrite
      #     unless self.remote_path.present?
      #       return true if self.set_remote_path(contents)
      #     end

      #     if contents.try(:first).is_a?(self.klass)
      #       @loaded = true
      #       return @internal_object = contents
      #     elsif contents.instance_of?(self.class)
      #       @loaded = true
      #       return @internal_object = contents.internal_object
      #     elsif contents.is_a?(Array)
      #       @loaded = true
      #       return @internal_object = self.klass.instantiate_collection(
      #         contents
      #       )
      #     # we have only provided the resource definition - that's the same
      #     # as a blank array in this case
      #     elsif contents.nil?
      #       return @internal_object = []
      #     else
      #       raise ArgumentError.new(
      #         "#{contents} must be a #{self.klass}, #{self.class}, " +
      #         "Array or nil"
      #       )
      #     end
      #   end

      #   def ==(other)
      #     return false if self.class != other.class
      #     if self.internal_object.is_a?(Array)
      #       self.internal_object.sort.each_with_index do |elem, i|
      #         return false if other.internal_object.sort[i].attributes != elem.attributes
      #       end
      #     end
      #     return true
      #   end

      #   def serializable_hash(options)
      #     self.internal_object.collect{|obj| obj.serializable_hash(options) }
      #   end

      #   protected

      #   def to_condition
      #     obj = nil
      #     obj = self.internal_object if self.loaded?
      #     ApiResource::Conditions::MultiObjectAssociationCondition.new(
      #       self.klass, self.remote_path, obj
      #     )
      #   end

      #   def load(opts = {})
      #     res = self.to_condition.load
      #     @loaded = true
      #     res
      #   end

      #   def set_remote_path(opts)
      #    if opts.is_a?(Array) && opts.first.is_a?(Hash)
      #       if opts.first.symbolize_keys[self.class.remote_path_element.to_sym]
      #         service_uri_el = opts.shift
      #       else
      #         service_uri_el = {}
      #       end
      #     elsif opts.is_a?(Hash)
      #       service_uri_el = opts
      #     else
      #       service_uri_el = {}
      #     end

      #     @remote_path = service_uri_el.symbolize_keys.delete(
      #       self.class.remote_path_element.to_sym
      #     )

      #     return @remote_path.present?
      #   end

      end

  end

end