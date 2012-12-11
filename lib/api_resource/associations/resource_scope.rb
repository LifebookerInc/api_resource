module ApiResource
  module Associations
    class ResourceScope < AbstractScope

      include Enumerable

      alias_method :all, :internal_object

      def each(*args, &block)
        self.internal_object.each(*args, &block)
      end

      # perform a find with a given set of query params
      def load(opts = {})
        ret = self.klass.all(:params => opts)
        @loaded = true
        ret
      end
    end
  end
end
