
module ApiResource

  module Finders

    class AbstractFinder

      attr_accessor :condition, :klass
      attr_reader :found, :internal_object

      # TODO: Make this list longer since there are for sure more methods to delegate
      delegate :to_s, :inspect, :reload, :present?, :blank?, :size, :count, :to => :internal_object

      def initialize(klass, condition)
        @klass = klass
        @condition = condition
        @found = false

        @klass.load_resource_definition
      end

      #
      # Allows us to respond correctly to instance_of? based
      # on our internal_object
      #
      # @param  klass [Class] Class to check
      #
      # @return [Boolean]
      def instance_of?(klass)
        super || self.internal_object.instance_of?(klass)
      end

      #
      # Allows us to respond correctly to is_a? based
      # on our internal_object
      #
      # @param  klass [Class] Class to check
      #
      # @return [Boolean]
      def is_a?(klass)
        super || self.internal_object.is_a?(klass)
      end

      #
      # Allows us to respond correctly to kind_of? based
      # on our internal_object
      #
      # @param  klass [Class] Class to check
      #
      # @return [Boolean]
      def kind_of?(klass)
        self.is_a?(klass)
      end

      #
      # Return the headers for our response from
      # the server
      #
      # @return [Hash] Headers hash
      def headers
        self.response.try(:headers)
      end

      def internal_object
        # If we've already tried to load return what we've got
        if instance_variable_defined?(:@internal_object)
          return instance_variable_get(:@internal_object)
        end
        # If we haven't tried to load then just call load
        self.load
      end

      def load
        raise NotImplementedError("Must be defined in a subclass")
      end

      #
      # Offset returned from the server
      #
      # @return [Fixnum]
      def offset
        self.headers.try(:[], 'ApiResource-Offset').to_i
      end

      #
      # Is this a paginated find?
      #
      # @return [Boolean]
      def paginated?
        @condition.paginated?
      end

      #
      # Total number of entries the server has told us are
      # in our collection
      #
      # @return [Fixnum]
      def total_entries
        self.headers.try(:[], 'ApiResource-Total-Entries').to_i
      end

      #
      # Getter for our response from the server
      #
      # @return [ApiResource::Response]
      def response
        @response ||= begin
          self.klass.connection.get(self.build_load_path)
        end
      end

      def all(*args)
        if args.blank?
          self.internal_object
        else
          self.klass.send(:all, *args)
        end
      end

      # proxy unknown methods to the internal_object
      def method_missing(method, *args, &block)
        self.internal_object.send(method, *args, &block)
      end

      protected

      # This returns a hash of class_names (given by the condition object)
      # to an array of objects
      def load_includes(id_hash)
        # Quit early if the condition is not eager
        return {} unless self.condition.eager_load?
        # Otherwise go through each class_name that is included, and load the ids
        # given in id_hash, at this point we know all these associations have their
        # proper names

        hsh = HashWithIndifferentAccess.new
        id_hash = HashWithIndifferentAccess.new(id_hash)
        # load each individually
        self.condition.included_objects.inject(hsh) do |accum, assoc|
          id_hash[assoc].each_slice(400).each do |ids|
            accum[assoc.to_sym] ||= []
            accum[assoc.to_sym].concat(
              self.klass.association_class(assoc).all(
                :params => {:ids => ids}
              )
            )
          end
          accum
        end

        hsh
      end

      def apply_includes(objects, includes)
        Array.wrap(objects).each do |obj|
          includes.each_pair do |assoc, vals|
            ids_to_keep = Array.wrap(obj.send(obj.class.association_foreign_key_field(assoc)))
            to_keep = vals.select{|elm| ids_to_keep.include?(elm.id)}
            # if this is a single association take the first
            # TODO: subclass instead of this
            if self.klass.has_many?(assoc)
              obj.send("#{assoc}=", to_keep, false)
            else
              obj.send("#{assoc}=", to_keep.first, false)
            end
          end
        end
      end

      def build_load_path
        raise "This is not finding an association" unless self.condition.remote_path

        path = self.condition.remote_path
        # add a format if it doesn't exist and there is no query string yet
        path += ".#{self.klass.format.extension}" unless path =~ /\./ || path =~/\?/
        # add the query string, allowing for other user-provided options in the remote_path if we have options
        unless self.condition.blank_conditions?
          path += (path =~ /\?/ ? "&" : "?") + self.condition.to_query
        end
        path
      end

    end

  end

end