module ApiResource

  module Conditions

    #
    # Superclass for all conditions, implements passing most properties
    # up to the owner if it is set and deals with returning defaults
    #
    # @author [ejlangev]
    #
    class AbstractCondition

      # All conditions are collections and are therefore
      # enumerable
      include Enumerable

      # @!attribute [r] basis
      # @return [Object] The object this class is a condition over,
      # either an association proxy or a class
      attr_reader :basis

      # @!attribute [r] internal_object
      # @return [Array<Object>] [description]
      attr_reader :internal_object

      # @!attribute [r] owner
      # @return [ApiResource::Conditions::AbstractCondition]
      attr_reader :owner

      #
      # @param  basis [Object] Object to base this condition on,
      # tells what class to load and where to find it
      def initialize(basis)
        @basis = basis
        @is_loaded = false
      end

      #
      # Causes the condition to load but wrapped in an AsyncDecorator
      # and therefore in the background
      #
      # @param  &block [Block] Block that takes the results of loading
      # the condition
      #
      # @return [ApiResource::Decorators::AsyncDecorator]
      def async(&block)
        ApiResource::Decorators::AsyncDecorator.new(
          construct_finder,
          &block
        )
      end

      #
      # Returns the hash of parameters that should be included when loading
      # this condition
      #
      # @return [Hash]
      def conditions
        self.owner.try(:conditions) || {}
      end

      #
      # Returns the current_page that this condition is on
      # in the pagination.  The default is 1
      #
      # @return [Integer]
      def current_page
        self.owner.try(:current_page) || 1
      end

      #
      # Implements enumerable for conditions
      #
      # @param  &block [Block] The block to pass to each
      #
      # @return [Iterator]
      def each(&block)
        self.internal_object.each(&block)
      end

      #
      # Do we need to eager load associations?
      #
      # @return [Boolean]
      def eager_load?
        self.owner.try(:eager_load?) || false
      end

      #
      # Cache the result of loading this association
      #
      # @param  time [Time] How long to cache for
      #
      # @return [ApiResource::Decorators::CachingDecorator]
      def expires_in(time)
        ApiResource::Decorators::CachingDecorator.new(self, time)
      end

      #
      # Takes the same arguments as the normal class method
      # finds but applies them to a condition.  Returns the actual
      # objects.  Always blocks.
      #
      # @param  *args [Array<Object>] The extra arguments
      #
      # @return [Array<Object>] The resulting records
      def find(*args)
        self.basis.find_with_condition(
          self,
          *args
        )
      end

      #
      # Returns the list of objects to include when this condition
      # gets loaded
      #
      # @return [Array<Symbol>] List of symbols of associations
      # to include
      def included_associations
        self.owner.try(:included_associations) || []
      end

      #
      # Implements the includes method for chaining with
      # associations and scopes
      #
      # @param  associations [Array<Symbol>]
      #
      # @return [ApiResource::Conditions::IncludeCondition]
      def includes(associations)
        result = self.basis.includes(associations)
        result.set_owner(self)
        result
      end

      #
      # Wrapper for the collection that will be
      # returned by this connection
      #
      # @return [Array<Object>]
      def internal_object
        load unless @is_loaded
        @internal_object
      end

      #
      # The offset we are currently at in our query
      # Returns 0 if we are not paginated
      #
      # @return [Fixnum]
      def offset
        self.owner.try(:offset) || 0
      end

      #
      # Implementation of method missing to deal
      # with scopes
      # @param  sym [Symbol] The name of the method
      # @param  *args [Array<Object>] The arguments
      # @param  &block [Block] Any block provided
      #
      # @return [Object]
      def method_missing(sym, *args, &block)
        # If this method call is a scope, proxy to the basis
        # to get a condition object and make this its owner
        if self.basis.scope?(sym)
          condition = self.basis.__send__(sym, *args, &block)
          condition.set_owner(self)
          return condition
        end

        self.internal_object.__send__(sym, *args, &block)
      end

      #
      # Implements pagination on scopes so it can be chained
      #
      # @param  opts = {} [Hash] The arguments to paginate
      #
      # @return [ApiResource::Conditions::PaginationCondition]
      def paginate(opts = {})
        result = self.basis.paginate(opts)
        result.set_owner(self)
        result
      end

      #
      # Reader for if this condition is paginated
      #
      # @return [Boolean]
      def paginated?
        self.owner.try(:paginated?) || false
      end

      #
      # Number of records per page if this is paginated
      # Returns 1 if not paginated
      #
      # @return [Fixnum]
      def per_page
        self.owner.try(:per_page) || 1
      end

      #
      # Removes the data associated with this condition
      # and marks it as not loaded.  It will be loaded the next time
      # it is needed.
      #
      # @return [Boolean] Always true
      def reload
        if instance_variable_defined?(:@internal_object)
          remove_instance_variable(:@internal_object)
        end
        @is_loaded = false
        true
      end

      #
      # Implementation of respond_to? that makes it look correct
      # for dealing with scopes
      #
      # @param  symbol [Symbol] The name of the method
      # @param  include_all = false [Boolean] Whether to search private
      # and protected methods
      #
      # @return [Boolean]
      def respond_to?(symbol, include_all = false)
        self.basis.scope?(symbol.to_sym) || super
      end

      #
      # Sets the owner of this condition which helps form
      # a chain of scopes
      #
      # @param  owner [ApiResource::Conditions::AbstractCondition]
      #
      # @return [Boolean] Always true
      def set_owner(owner)
        @owner = owner
        true
      end

      #
      # Total number of records found in the collection
      # if it is paginated
      #
      # @return [Integer]
      def total_entries
        self.internal_object.total_entries
      end

      #
      # The total number of pages in our collection or
      # 1 if it is not paginated
      #
      # @return [Fixnum]
      def total_pages
        self.owner.try(:total_pages) || 1
      end

      private

        #
        # Creates a finder object and uses it to load
        # the proper data.  Sets @internal_object and sets
        # @is_loaded to true
        #
        # @return [Array<Object>]
        def load
          # Actually deals with getting the proper finder object
          # and loading records
          finder = construct_finder
          # Now all we need to do is set internal_object
          @internal_object = finder.internal_object
          @is_loaded = true
          @internal_object
        end

        #
        # Constructs the proper finder object
        #
        # @return [ApiResource::Finders::AbstractFinder] [description]
        def construct_finder
          ApiResource::Finders::MultiObjectFinder.new(
            self.basis,
            self
          )
        end

    end

  end

end