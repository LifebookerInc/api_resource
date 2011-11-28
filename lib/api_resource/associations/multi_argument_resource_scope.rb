require 'api_resource/associations/dynamic_resource_scope'

module ApiResource
  module Associations
    class MultiArgumentResourceScope < DynamicResourceScope
      # initialize with a variable number of dynamic arguments
      def initialize(klass, current_scope, *dynamic_value)
        # pull off opts
        opts = dynamic_value.extract_options!
        # we always dynamic value to be an Array, so we don't use the splat here
        super(klass, current_scope, dynamic_value.flatten, opts)
      end
    end
  end
end