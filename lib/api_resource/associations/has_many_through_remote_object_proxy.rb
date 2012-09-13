module ApiResource
  module Associations
    module HasManyThroughRemoteObjectProxy
      def has_many_through_remote(association, options) 
        self.instance_eval do
          send(:define_method, association) do
            ApiResource.with_token(konfig.resources.lb_api_key) do
              send(options[:through]).collect{ |t| t.send(association.to_s.singularize) }.flatten  
            end
          end
        end
      end
    end    
  end
end
