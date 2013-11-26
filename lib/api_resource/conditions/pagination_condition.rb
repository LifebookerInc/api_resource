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

      #
      # Constructor - sets up the pagination options
      # @param  opts = {} [Hash] Pagination opts
      # @option opts [Fixnum] :page (1) Page we are on
      # @option opts [Fixnum] :per_page (10) Number per page
      def initialize(klass, opts = {})
        @page = opts[:page] || 1
        @per_page = opts[:per_page] || 10
        super({ page: @page, per_page: @per_page }, klass)
      end

      #
      # Are we paginated?
      #
      # @return [Boolean] true
      def paginated?
        true
      end

    end

  end

end