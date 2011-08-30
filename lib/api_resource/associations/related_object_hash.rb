module ApiResource
  module Associations 
    # RelatedObjectHash, re-defines dup to be recursive
    class RelatedObjectHash < HashWithIndifferentAccess
      def dup
        Marshal.load(Marshal.dump(self))
      end
      # use this behavior for clone too
      alias_method :clone, :dup
    end
  end
end