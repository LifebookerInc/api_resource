module ApiResource

  module Conditions

    #
    # Class to handle pagination params, passing
    # of pagination params along to the server, and the
    # retrieval of the headers from the response
    #
    # @author [dlangevin]
    #
    class PaginationCondition < AbstractCondition

      # @!attribute [r] page
      # @return [Integer] The page number to load
      attr_reader :page

      # @!attribute [r] per_page
      # @return [Integer] The number of records per page
      attr_reader :per_page

      #
      # Constructor - sets up the pagination options
      # @param  opts = {} [Hash] Pagination opts
      # @option opts [Fixnum] :page (1) Page we are on
      # @option opts [Fixnum] :per_page (10) Number per page
      def initialize(klass, opts = {})
        @page = (opts[:page] || 1).to_i
        @per_page = (opts[:per_page] || 10).to_i
        super(klass)
      end

      #
      # Returns the current page loaded from the
      # instance variable
      #
      # @return [Integer]
      def current_page
        return 1 if self.page < 1
        self.page
      end

      #
      # Returns the offset based on current_page and per_page
      #
      # @return [Integer]
      def offset
        (self.current_page - 1) * self.per_page
      end

      #
      # Are we paginated?
      #
      # @return [Boolean] true
      def paginated?
        true
      end

      #
      # Total number of pages in this collection based on the
      # total_entries
      #
      # @return [Integer]
      def total_pages
        (self.total_entries / self.per_page.to_f).ceil
      end

    end

  end

end