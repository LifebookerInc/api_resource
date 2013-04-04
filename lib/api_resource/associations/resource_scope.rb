module ApiResource
  module Associations
    class ResourceScope < AbstractScope

      # perform a find with a given set of query params
      def load(opts = self.to_hash)
        ret = self.klass.all(:params => opts)
        @loaded = true
        ret
      end
    end
  end
end
