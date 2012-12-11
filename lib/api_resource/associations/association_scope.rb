module ApiResource
  
  module Associations
   
    class AssociationScope < AbstractScope

      class_attribute :remote_path_element
      self.remote_path_element = :service_uri 

      attr_accessor :remote_path
      attr_reader :owner 
      
      # TODO: added owner - moved it to the end because the tests don't use it - it's useful here though
      def initialize(klass, owner, opts = {})
        super(klass)

        @owner = owner
        
        self.internal_object = opts
      end
      
      def ==(other)
         raise "Not Implemented: This method must be implemented in a subclass"
      end

      def scopes
        self.klass.scopes
      end

      protected
      
      # get the remote URI based on our config and options
      def build_load_path(options)
        path = self.remote_path
        # add a format if it doesn't exist and there is no query string yet
        path += ".#{self.klass.format.extension}" unless path =~ /\./ || path =~/\?/
        # add the query string, allowing for other user-provided options in the remote_path if we have options
        unless options.blank?
          path += (path =~ /\?/ ? "&" : "?") + options.to_query 
        end
        path
      end
    end
    
  end
  
end