module ApiResource

  module Conditions

    class AbstractCondition

      include Enumerable

      # @!attribute [r] association
      #   @return [Boolean] Are we an association?
      attr_reader :association

      # @!attribute [r] conditions
      #   @return [Hash] Hash of conditions
      attr_reader :conditions

      # @!attribute [r] included_objects
      #   @return [Array<Symbol>] List of associations to eager load
      attr_reader :included_objects

      # @!attribute [r] internal_object
      #   @return [Array<ApiResource::Base>] Underlying objects we found
      attr_reader :internal_object

      # @!attribute [r] klass
      #   @return [Class] Owner class
      attr_reader :klass

      # @!attribute [r] remote_path
      #   @return [String] Path to hit when we find stuff
      attr_reader :remote_path

      # TODO: add the other load forcing methods here for collections
      delegate :[], :[]=, :<<, :first, :second, :last, :blank?, :nil?,
        :include?, :push, :pop, :+, :concat, :flatten, :flatten!, :compact,
        :compact!, :empty?, :fetch, :map, :reject, :reject!, :reverse,
        :select, :select!, :size, :sort, :sort!, :uniq, :uniq!, :to_a,
        :sample, :slice, :slice!, :count, :present?, :delete_if,
        :to => :internal_object

      # need to figure out what to do with args in the subclass,
      # parent is the set of scopes we have right now
      def initialize(klass, args)
        @klass = klass
        @conditions = args.with_indifferent_access
        @klass.load_resource_definition
      end

      def all(*args)
        if args.blank?
          self.internal_object
        else
          self.find(*([:all] + args))
        end
      end

      #
      # Is this a find without any conditions
      #
      # @return [Boolean]
      def blank_conditions?
        self.conditions.blank?
      end

      #
      # Accessor for the current page if we
      # are paginated.  Returns 1 if we are not
      # paginated or have an invalid page
      #
      # @return [Fixnum] [description]
      def current_page
        return 1 unless self.paginated?
        return 1 if @conditions[:page].to_i < 1
        return @conditions[:page].to_i
      end

      def each(&block)
        self.internal_object.each(&block)
      end

      #
      # Are we set up to eager load associations?
      #
      # @return [Boolean]
      def eager_load?
        self.included_objects.present?
      end

      def expires_in(time)
        ApiResource::Decorators::CachingDecorator.new(self, time)
      end

      # implement find that accepts an optional
      # condition object
      def find(*args)
        self.klass.find(*(args + [self]))
      end

      def included_objects
        Array.wrap(@included_objects)
      end

      def internal_object
        return @internal_object if @loaded
        @internal_object = self.instantiate_finder
        @internal_object.load
        @loaded = true
        @internal_object
      end

      # TODO: review the hierarchy that makes this necessary
      # consider changing it to alias method
      def load
        self.internal_object
      end

      def loaded?
        @loaded == true
      end

      # TODO: Remove the bang, this doesn't modify anything
      def merge!(cond)

        # merge included objects
        @included_objects = self.included_objects | cond.included_objects

        # handle pagination
        if cond.paginated?
          @paginated = true
        end

        # merge conditions
        @conditions = @conditions.merge(cond.to_hash)

        # handle associations
        if cond.association
          @association =  true
        end
        # handle remote path copying
        @remote_path ||= cond.remote_path

        return self
      end

      #
      # The offset we are currently at in our query
      # Returns 0 if we are not paginated
      #
      # @return [Fixnum]
      def offset
        return 0 unless self.paginated?
        prev_page = self.current_page.to_i - 1
        prev_page * self.per_page
      end

      #
      # Reader for whether or not we are paginated
      #
      # @return [Boolean]
      def paginated?
        @paginated
      end

      #
      # Number of records per page if paginated
      # Returns 1 if number is out of range or if pagination
      # is not enabled
      #
      # @return [Fixnum]
      def per_page
        return 1 unless self.paginated?
        return 1 if @conditions["per_page"].to_i < 1
        return @conditions["per_page"].to_i
      end

      def reload
        if instance_variable_defined?(:@internal_object)
          remove_instance_variable(:@internal_object)
        end
        @loaded = false
      end

      def to_query
        CGI.unescape(to_query_safe_hash(self.to_hash).to_query)
      end

      def to_hash
        self.conditions.to_hash
      end

      #
      # Total number of records found in the collection
      # if it is paginated
      #
      # @return [Fixnum]
      def total_entries
        self.internal_object.total_entries
      end

      #
      # The total number of pages in our collection
      # or 1 if it is not paginated
      #
      # @return [Fixnum]
      def total_pages
        return 1 unless self.paginated?
        return (self.total_entries / self.per_page.to_f).ceil
      end

      protected

      #
      # Proxy all calls to the base finder class
      # @param  sym [Symbol] Method name
      # @param  *args [Array<Mixed>] Args
      # @param  &block [Proc] Block
      #
      # @return [Mixed]
      def method_missing(sym, *args, &block)
        result = @klass.send(sym, *args, &block)

        if result.is_a?(ApiResource::Conditions::AbstractCondition)
          return self.dup.merge!(result)
        else
          return result
        end
      end

      def instantiate_finder
        ApiResource::Finders::ResourceFinder.new(self.klass, self)
      end

      def to_query_safe_hash(hash)
        hash.each_pair do |k,v|
          hash[k] = to_query_safe_hash(v) if v.is_a?(Hash)
          hash[k] = true if v == {}
        end
        return hash
      end

    end

  end

end