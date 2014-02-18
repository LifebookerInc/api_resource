module ApiResource

	module Conditions

    #
    # Class that deals with holding names of associations
    # to include in a scope chain
    #
    # @author [ejlangev]
    #
		class IncludeCondition < AbstractCondition

      # @!attribute [r] included_associations
      # @return [Array<Symbol>]
      attr_reader :included_associations

      #
      # @param  klass [Class] The class to base the conditions on
      # @param  includes [Array<Symbol>] An array of symbol names
      # of associations
			def initialize(klass, includes)
				@included_associations = Array.wrap(
          includes
        )
        super(klass)
			end

      #
      # Actual implementation that adds the associations
      # this object knows about into the list
      #
      # @return [Array<Symbol>]
      def included_associations
        super + @included_associations
      end

		end

	end

end